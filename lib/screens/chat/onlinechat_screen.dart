import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:hemailer/screens/chat/onlinechat_hist_screen.dart';
import 'package:hemailer/utils/websocket_receiver.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:hemailer/widgets/drawer_widget.dart';

class OnlineChatScreen extends StatefulWidget {
  final UserInfo userInfo;
  OnlineChatScreen({Key key, @required this.userInfo}) : super(key: key);
  @override
  _OnlineChatScreenState createState() => _OnlineChatScreenState();
}

class _OnlineChatScreenState extends State<OnlineChatScreen>{
  List<dynamic> filteredSubs = new List<dynamic>();
  TextEditingController txtSearch = TextEditingController();
  List<dynamic> allClients;
  List<dynamic> newMsgCounts;
  bool _progressBarActive = false;
  final assetsAudioPlayer = AssetsAudioPlayer();
  int newConntectedClient = 0;

  OnlineChatSocket onlineSocket;
  @override
  void initState(){
    super.initState();
    getNewMsgCount();
    
    onlineSocket = new OnlineChatSocket(widget.userInfo);
    onlineSocket.addListener((){
      dynamic jsonResponse = onlineSocket.recentMsg;
      if(jsonResponse.containsKey('msg_type')){
        if(jsonResponse["msg_type"] == "online-info"){
          var clients = jsonResponse["msg"]["clients"];
          List<dynamic> tmpClients = new List<dynamic>();
          if(clients.toString() != "[]"){
            
            for (var key in clients.keys){
              clients[key]["id"] = key;
              clients[key]["new_msg"] = "0";
              if(clients[key]["connected"] == "READY"){
                newConntectedClient ++;
              }
              tmpClients.add(clients[key]);
            }
          }
          setState(() {
            allClients = tmpClients;
          });
          filterSearchResults(txtSearch.text);
          if(newConntectedClient > 0){
            assetsAudioPlayer.open(
              "assets/alert_4s.mp3",
            );
            assetsAudioPlayer.loop = true;
            assetsAudioPlayer.play();
            
          }
        }else if(jsonResponse["msg_type"] == "receive-msg"){
          setState(() {
            for(var client in allClients){
              if(client["id"] == jsonResponse["senderID"]){
                client["new_msg"] = (int.parse(client["new_msg"]) + 1).toString();
              }
            }
          });
        }
      }
    });
  }
  void getNewMsgCount(){
    final body = {
      "receiver_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getOnlineChatNewMsg(body).then((response) {
      newMsgCounts = response;
      if(newMsgCounts != null && allClients != null){
        for(var client in allClients){
          client["new_msg"] = "0";
        }
        for (var newMsg in newMsgCounts){
          for(var client in allClients){
            if(client["id"] == newMsg["sender_id"]){
              client["new_msg"] = newMsg["new_msg_count"];
            }
          }
        }
      }
      setState(() {
        _progressBarActive = false;
      });
    });
  }
  Future<void> deleteClient(dynamic clientInfo) async {
    final ConfirmAction action = await confirmDialog(context);
    
    if(action == ConfirmAction.YES){
      var messageJSON = {
        "msg_type": "delete-user",
        "sender_id": widget.userInfo.id,
        "receiver_id": clientInfo["id"],
        "chat_message": "",
        "parentID": widget.userInfo.id,
        "msg_owner": "agent",
      };
      onlineSocket.sendMsg(messageJSON);
      final body = {
        "email_id": clientInfo["id"],
        "user_id": widget.userInfo.id,
      };
      ApiService.deleteOnlineClient(body).then((response) {
        if (response != null && response["status"]) {
          
        }else{
          showErrorToast("Something error");
        }
      });
    }
    
  }
  void saveClient(dynamic clientInfo){
    final body = {
      "email_id": clientInfo["id"],
      "user_id": widget.userInfo.id,
    };
    ApiService.saveOnlineClient(body).then((response) {
      if (response != null && response["status"]) {
        showSuccessToast("Saved");
      }else{
        showErrorToast("Something error");
      }
    });
    
  }
  void selectClient(dynamic clientInfo, BuildContext context){
    if(clientInfo["connected"] == "READY"){
      newConntectedClient = 0;
      assetsAudioPlayer.stop();
      var messageJSON = {
        "msg_type": "chat-connected",
        "sender_id": widget.userInfo.id,
        "receiver_id": clientInfo["id"],
        "parentID": widget.userInfo.id,
        "msg_owner": "agent",
      };
      onlineSocket.sendMsg(messageJSON);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineChatHistoryScreen(clientInfo:clientInfo, userInfo: widget.userInfo, onlineSocket: onlineSocket,),
      ),
    ).then((value){
      getNewMsgCount();
    });
    
  }
  void filterSearchResults(String query) {
    if(query.isNotEmpty) {
      List<dynamic> dummyListData = List<dynamic>();
      allClients.forEach((item) {
        if(item["name"].toString().toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        filteredSubs.clear();
        filteredSubs.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        filteredSubs.clear();
        filteredSubs.addAll(allClients);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: const Text("Online Chat"),),
      drawer: AppDrawer(userInfo: widget.userInfo,),
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: TextField(
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                  controller: txtSearch,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(0.0),
                    labelText: "Search",
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                ),
              ),
              Expanded(
                child:ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredSubs !=null? filteredSubs.length: 0,
                  itemBuilder: (context, index) {
                    return Card( //                           <-- Card widget
                      child: ListTile(
                        title: Row(
                        children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: Text(filteredSubs[index]["name"]),
                            ),
                            Visibility(
                              visible: filteredSubs[index]["connected"] == "READY" ? true: false,
                              child: Badge(
                                badgeContent: Text('Connecting...', style: TextStyle(color: Colors.white),),
                                badgeColor:  Color(0xff00c851),
                                shape: BadgeShape.square,
                                elevation:6.0,
                                padding:EdgeInsets.all(5.0),
                              )
                            ),
                          ],
                        ),
                        subtitle: Row(
                        children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: Text(filteredSubs[index]["email"]),
                            ),
                            Visibility(
                              visible: filteredSubs[index]["new_msg"] != "0" ? true: false,
                              child: Badge(
                                badgeContent: Text(filteredSubs[index]["new_msg"], style: TextStyle(color: Colors.white),),
                                badgeColor:  Colors.red,
                                elevation:6.0,
                                padding:EdgeInsets.all(5.0),
                              )
                            ),
                          ],
                        ),
                        leading: Badge(
                          badgeContent: Text(' '),
                          badgeColor: filteredSubs[index]["online"]? Color(0xff00c851): Color(0xffc23616),
                          elevation:6.0,
                          padding:EdgeInsets.all(5.0),
                          position: BadgePosition.bottomRight(bottom: 0.0, right: 1.0),
                          child: Container(
                            width: 54.0,
                            height: 54.0,
                            decoration: new BoxDecoration(
                              color: const Color(0xff7c94b6),
                              image: new DecorationImage(
                                image: new NetworkImage(baseURL + 'uploads/avatar/profile.jpg'),
                              ),
                              borderRadius: new BorderRadius.all(new Radius.circular(27.0)),
                              border: new Border.all(
                                color: filteredSubs[index]["online"]? Colors.green: Colors.red,
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            InkWell(
                              onTap: (){
                                deleteClient(filteredSubs[index]);
                              },
                              child: Icon(
                                Icons.delete, color:Colors.blueAccent, size:20.0,
                              ),
                            ), 
                            InkWell(
                              onTap: (){
                                saveClient(filteredSubs[index]);
                              },
                              child: Icon(
                                Icons.save, color:Colors.blueAccent, size:20.0,
                              ),
                            ), 
                          ],
                        ),
                        onTap: () {
                          selectClient(filteredSubs[index], context);
                        },
                      ),
                    );
                  }
                )
              )
            ],
          ),
        ),
      ),
    );
  }
  
}
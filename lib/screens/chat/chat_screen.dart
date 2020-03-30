import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:hemailer/screens/chat/chat_hist_screen.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:hemailer/utils/websocket_receiver.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/widgets/drawer_widget.dart';

class ChatScreen extends StatefulWidget {
  final UserInfo userInfo;
  ChatScreen({Key key, @required this.userInfo}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>{
  List<dynamic> filteredSubs = new List<dynamic>();
  TextEditingController txtSearch = TextEditingController();
  List<dynamic> allClients;
  List<dynamic> newMsgCounts;
  bool _progressBarActive = false;
  
  ChatSocket chatSocket;
  @override
  void initState(){
    super.initState();
    getChatUsers();
  }
  void getChatUsers(){
    final body = {
      "user_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getChatUsers(body).then((response) {
      setState(() {
        allClients = response;
        for(var client in allClients){
          client["online"] = false;
        }
        _progressBarActive = false;
      });
      chatSocket = new ChatSocket(widget.userInfo);
      chatSocket.addListener((){
        dynamic jsonResponse = chatSocket.recentMsg;
        if(jsonResponse.containsKey('msg_type')){
          if(jsonResponse["msg_type"] == "online-info"){
            var clients = jsonResponse["msg"];
            for (var key in clients.keys){
              for (var client in allClients){
                if(client["id"] == key){
                  client["online"] = clients[key]["online"];
                }
              }
            }
            filterSearchResults(txtSearch.text);
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
      filterSearchResults(txtSearch.text);
    });
  }
  void getNewMsgCount(){
    final body = {
      "receiver_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getChatNewMsg(body).then((response) {
      var newMsgCounts = response;
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
  void selectClient(dynamic clientInfo, BuildContext context){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(clientInfo:clientInfo, userInfo: widget.userInfo, chatSocket: chatSocket,),
      ),
    ).then((onValue){
      getNewMsgCount();
    });
  }
  void filterSearchResults(String query) {
    if(query.isNotEmpty) {
      List<dynamic> dummyListData = List<dynamic>();
      allClients.forEach((item) {
        if(item["username"].toString().toLowerCase().contains(query.toLowerCase())) {
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
      appBar: AppBar(title: const Text("Chat"),),
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
                              child: Text(filteredSubs[index]["username"]),
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
                                image: new NetworkImage(filteredSubs[index]["photo_url"] == "" ? baseURL + 'uploads/avatar/profile.jpg' : baseURL + filteredSubs[index]["photo_url"]),
                              ),
                              borderRadius: new BorderRadius.all(new Radius.circular(27.0)),
                              border: new Border.all(
                                color: filteredSubs[index]["online"]? Colors.green: Colors.red,
                                width: 1.0,
                              ),
                            ),
                          ),
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
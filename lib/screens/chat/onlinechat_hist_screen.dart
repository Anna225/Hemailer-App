import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:hemailer/utils/websocket_receiver.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';

class OnlineChatHistoryScreen extends StatefulWidget {
  final UserInfo userInfo;
  final OnlineChatSocket onlineSocket;
  final dynamic clientInfo; 
  OnlineChatHistoryScreen({Key key, @required this.userInfo, this.clientInfo, this.onlineSocket}) : super(key: key);
  @override
  _OnlineChatHistoryScreenState createState() => _OnlineChatHistoryScreenState();
}

class _OnlineChatHistoryScreenState extends State<OnlineChatHistoryScreen>{
  TextEditingController _txtMsg = TextEditingController();
  ScrollController _scrollController = new ScrollController();
  
  List<dynamic> allChatMsg;
  bool _progressBarActive = false;
  int msgCount = 0;
  // WebsocketManager socket;
  var recentMsg;
  @override
  void initState(){
    super.initState();
    
    final body = {
      "receiver_id": widget.clientInfo["id"],
      "sender_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getOnlineChatHistory(body).then((response) {
      setState(() {
        allChatMsg = response["hist_data"];
        msgCount = int.parse(response["msg_count"]);
        _progressBarActive = false;
      });
      
    });
    
    receiveMSG();
  }
  void receiveMSG(){
    widget.onlineSocket.addListener((){
      dynamic newMsg = widget.onlineSocket.recentMsg;
      if(newMsg["msg_type"] == "sender-msg" && (newMsg["senderID"] == widget.userInfo.id && newMsg["receiverID"] == widget.clientInfo["id"])){
        recentMsg = {
          "sender_id" : newMsg["senderID"],
          "receiver_id" : newMsg["receiverID"],
          "message" : newMsg["msg"],
          "created_at": newMsg["msg_time"]
        };
        if(mounted){
          setState(() {
            allChatMsg.add(recentMsg);
            msgCount += 1;
          });
        }
        _txtMsg.text = "";
      }else if(newMsg["msg_type"] == "receive-msg" && (newMsg["senderID"] == widget.clientInfo["id"] && newMsg["receiverID"] == widget.userInfo.id)){
        recentMsg = {
          "sender_id" : newMsg["senderID"],
          "receiver_id" : newMsg["receiverID"],
          "message" : newMsg["msg"],
          "created_at": newMsg["msg_time"]
        };
        if(mounted){
          setState(() {
            allChatMsg.add(recentMsg);
            msgCount += 1;
          });
        }
      }

    });
  }
  void sendMSG(){
    var messageJSON = {
      "msg_type": "chat-message",
      "sender_id": widget.userInfo.id,
      "receiver_id": widget.clientInfo["id"],
      "chat_message": _txtMsg.text,
      "parentID": widget.userInfo.id,
      "msg_owner": "agent",
      "attach_url": "",
      "attach_real_name": "",
    };
    if(_txtMsg.text != ""){
      widget.onlineSocket.sendMsg(messageJSON);
    }
  }
  void readMsg(){
    print("readMsg");
    final body = {
      "receiver_id": widget.clientInfo["id"],
      "sender_id": widget.userInfo.id,
    };
    print(body);
    ApiService.readOnlineChatMsg(body).then((response) {
      if (response != null && response["status"]) {
        
      }else{
        showErrorToast("Something error");
      }
    });
  }
  Future<void> deleteClientHistory() async {
    // delete chat history on database
    final ConfirmAction action = await confirmDialog(context);
    
    if(action == ConfirmAction.YES){
      final body = {
        "receiver_id": widget.clientInfo["id"],
        "sender_id": widget.userInfo.id,
      };
      ApiService.deleteOnlineChatHistory(body).then((response) {
        if (response != null && response["status"]) {
          setState(() {
            allChatMsg.clear();
            msgCount = 0;
          });
        }else{
          showErrorToast("Something error");
        }
      });
    }
  }
  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }
  @override
  Widget build(BuildContext context) {
    
    final msgSenderRow = Row(
      children: <Widget>[
        Expanded(
          flex: 9,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 2.0),
            child: TextField(
              style: normalStyle,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
                hintText: "Type message...",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
              controller: _txtMsg,
              onTap: (){
                readMsg();
              },
            ),
          )
        ),
        Expanded(
          flex: 1,
          child:Material(
            color: Colors.white,
            child: Center(
              child: Ink(
                decoration: const ShapeDecoration(
                  color: Colors.blue,
                  shape: CircleBorder(side: BorderSide(color: Colors.blue, width: 1)),
                ),
                child: IconButton(
                  icon: Icon(Icons.send, ),
                  color: Colors.white,
                  onPressed: () {
                    sendMSG();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.0,)

      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return Scaffold(
      appBar: AppBar(title: const Text("Online Chat"),),
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: <Widget>[
              Card( //                           <-- Card widget
                child: ListTile(
                  title: Text(widget.clientInfo["name"] + " (" + widget.clientInfo["email"] + ")"),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top:12.0),
                    child: Text(msgCount.toString() +" Messages"),
                  ),
                  leading: Badge(
                    badgeContent: Text(' '),
                    badgeColor: widget.clientInfo["online"]? Color(0xff00c851): Color(0xffc23616),
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
                          color: widget.clientInfo["online"]? Colors.green: Colors.red,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  trailing: InkWell(
                    onTap: (){
                      deleteClientHistory();
                    },
                    child: Icon(
                      Icons.delete, color:Colors.blueAccent, size:20.0,
                    ),
                  ), 
                  
                ),
              ),
              Expanded(
                child:ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: allChatMsg !=null? allChatMsg.length: 0,
                  itemBuilder: (context, index) {
                    return Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: allChatMsg[index]["sender_id"]== widget.userInfo.id ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children:<Widget>[
                            SizedBox(width: 10.0,),
                            Card(
                              color: allChatMsg[index]["sender_id"]== widget.userInfo.id ? Color(0xffdaf5fc) : Color(0xfff1f6f8),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 5.0),
                                child: Container(
                                  constraints: new BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 84),
                                  child:Text(allChatMsg[index]["message"], style: normalStyle,)
                                )
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            SizedBox(width: 10.0,),
                          ], 
                        ),
                        Row(
                          mainAxisAlignment: allChatMsg[index]["sender_id"]== widget.userInfo.id ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children:<Widget>[
                            SizedBox(width: 10.0,),
                            Padding(
                              padding: EdgeInsets.fromLTRB(15.0, 2.0, 15.0, 2.0),
                              child: Text(allChatMsg[index]["created_at"], style: normalStyle.copyWith(fontSize: 11.0),)
                            ),
                            SizedBox(width: 10.0,),
                          ], 
                        ),
                      ],
                    );
                  }
                )
              ),
              msgSenderRow
            ],
          ),
        ),
      ),
    );
  }
}
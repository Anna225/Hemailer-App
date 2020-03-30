import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:hemailer/utils/contacts_search_dlg.dart';


class SendInvoiceScreen extends StatefulWidget {
  final dynamic contactInfo;
  final List<dynamic> allContacts;
  final UserInfo userInfo;
  SendInvoiceScreen({Key key, @required this.contactInfo, this.userInfo, this.allContacts}) : super(key: key);
  @override
  _SendInvoiceScreenState createState() => _SendInvoiceScreenState();
  
}

class _SendInvoiceScreenState extends State<SendInvoiceScreen>{
  TextEditingController _txtToEmail = new TextEditingController();
  TextEditingController _txtFromEmail = new TextEditingController();
  bool _progressBarActive = false;
  
  List<DropdownMenuItem> itemsTemplate = [];
  
  String folderID = "Saved Template:0";
  String tmpID;
  String tmpThumb;
  String expireMinutes = "0";
  List<dynamic> templates;

  List<dynamic> selectedContacts = new List<dynamic>();
  @override
  void initState(){
    super.initState();
    selectedContacts.add(widget.contactInfo);
    
    final body = {
      "user_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getInvoiceTmp(body).then((response) {
      setState(() {
        _progressBarActive = false;
        templates = response;
        for(var folder in templates){
          itemsTemplate.add(new DropdownMenuItem(
            child: new Text(
              folder["name"]
            ),
            value: folder["name"]+":"+folder["id"],
          ));
        }
      });
    });
  }
  
  String getTmpThumb(String tmpID){
    String tmpStrID = tmpID.toString().split(":")[1];
    for(var tmp in templates){
      if(tmp["id"]==tmpStrID){
        return tmp["tmp_thumb"];
      }
    }
    return null;
  }
  
  void sendInvoiceTmp(BuildContext context){
    if(_txtFromEmail.text==""){
      showErrorToast("Please fill from email");
    }else if(selectedContacts.length == 0){
      showErrorToast("Please select to email");
    }else if(tmpID == null){
      showErrorToast("Please select template");
    }else{
      List<String> arrSelToEmailID = new List<String>();
      for (var to in selectedContacts){
        arrSelToEmailID.add(to["id"]);
      }
      String selToEmailID = arrSelToEmailID.join(", ");
      String selTmpID = tmpID.toString().split(":")[1];
      String selFromEmail = _txtFromEmail.text;
      
      final body = {
        "user_id": widget.userInfo.id,
        "tmp_id": selTmpID,
        "receiver_id": selToEmailID,
        "sender": selFromEmail,
      };
      
      ApiService.sendInvoiceTmp(body).then((response) {
        if (response != null && response["status"]) {
          showSuccessToast("Sent invoice successfully");
        }else{
          showErrorToast("Something error");
        }
      });
    }
  }
  void addToContacts(BuildContext context){
    showDialog(
      context: context,
      builder: (context) {
        return ContactSearchDlg(
          contacts: widget.allContacts,
          selectedContacts: selectedContacts,
          onSelectedContactsListChanged: (contacts) {
            selectedContacts = contacts;
            if(selectedContacts.length>0){
              _txtToEmail.text = selectedContacts.length > 1 ? selectedContacts[0]["name"] + " + " + (selectedContacts.length -1).toString() +" contacts": selectedContacts[0]["name"];
            }else{
              _txtToEmail.text = "";
            }
            
          }
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    if(selectedContacts.length>0){
      _txtToEmail.text = selectedContacts.length > 1 ? selectedContacts[0]["name"] + " + " + (selectedContacts.length -1).toString() +" contacts": selectedContacts[0]["name"];
    }else{
      _txtToEmail.text = "";
    }
    _txtFromEmail.text = widget.userInfo.userEmail;
    final titleButtonRow = Row(
      children: <Widget>[
        Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("New Invoice", style:normalStyle.copyWith(fontSize: 25.0, fontWeight: FontWeight.bold ),),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.all(6.0),
            child: FlatButton.icon(
              color: Colors.blueAccent,
              icon: Icon(Icons.send, color: Colors.white,), //`Icon` to display
              label: Text('Send', style: normalStyle.copyWith(color: Colors.white,),), //`Text` to display
              onPressed: () {
                sendInvoiceTmp(context);
              },
            )
          )
        ),
      ],
    );
    final toEmailRow = Row(
      children: <Widget>[
        Expanded(
          flex: 8,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 0.0),
            child: TextField(
              enabled: false,
              style: normalStyle,
              keyboardType: TextInputType.text,
              decoration: new InputDecoration(labelText: 'To',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
              controller: _txtToEmail,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 0.0),
            child: IconButton(icon: Icon(Icons.person_add, size: 35.0, color: Colors.blueAccent,),  onPressed: (){
              addToContacts(context);
            }),
            
          )
        ),
      ],
    );
    final fromEmailRow = Padding(
      padding: EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 12.0),
      child: TextField(
        style: normalStyle,
        enabled: widget.userInfo.emailChange == "YES" ? true: false,
        keyboardType: TextInputType.text,
        decoration: new InputDecoration(labelText: 'From',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtFromEmail,
      ),
    );
    final templateRow = Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.fromLTRB(30.0, 12.0, 0.0, 0),
            child: Text("Template", style:normalStyle,),
          ),
        ),
        Expanded(
          flex: 7,
          child: SearchableDropdown(
            items: itemsTemplate,
            value: tmpID,
            isExpanded:false,
            hint: new Text(
              'Select Template'
            ),
            searchHint: new Text(
              'Select Template',
              style: new TextStyle(
                  fontSize: 20
              ),
            ),
            onChanged: (value) {
              setState(() {
                tmpID = value;
                tmpThumb = getTmpThumb(tmpID);
              });
            },
          )
        ),
      ],
    );
    
    return Scaffold(
      appBar: AppBar(title: const Text("Send Invoice"),),
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      titleButtonRow,
                      toEmailRow,
                      fromEmailRow,
                      templateRow,
                      Card(
                        margin: EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 10.0),
                        child: Image(
                          image: tmpThumb != null? NetworkImage(tmpThumb):AssetImage("assets/default.jpg"),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ],
                  )
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}


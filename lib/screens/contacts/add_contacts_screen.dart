import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ContactAddScreen extends StatefulWidget {
  final dynamic contactInfo;
  final UserInfo userInfo;
  ContactAddScreen({Key key, @required this.contactInfo, this.userInfo}) : super(key: key);
  @override
  _ContactAddScreenState createState() => _ContactAddScreenState();
  
}

class _ContactAddScreenState extends State<ContactAddScreen>{
  TextEditingController _txtName = new TextEditingController();
  TextEditingController _txtEmail = new TextEditingController();
  TextEditingController _txtPhone = new TextEditingController();
  TextEditingController _txtAddress = new TextEditingController();
  TextEditingController _txtNotes = new TextEditingController();
  TextEditingController _txtCreatedAt = new TextEditingController();
  bool _bNewSub = true;
  bool _bCancelSub = false;
  bool _bRecurringSub = false;
  var format = new DateFormat("yyyy-MM-dd");
  var now = new DateTime.now();
  bool _progressBarActive = false;
  @override
  void initState(){
    super.initState();
    // edit page
    if(widget.contactInfo != null){
      initContact();
    }else{
      _txtCreatedAt.text = format.format(now);
    }
  }
  void initContact(){
    _txtName.text = widget.contactInfo["name"];
    _txtEmail.text = widget.contactInfo["email"];
    _txtPhone.text = widget.contactInfo["phone"];
    _txtAddress.text = widget.contactInfo["address"];
    _txtNotes.text = widget.contactInfo["notes"];
    _txtCreatedAt.text = widget.contactInfo["created_at"];
    setState(() {
      _bNewSub = widget.contactInfo["new_subscriber"]=="YES" ? true : false;
      _bCancelSub = widget.contactInfo["cancel_subscriber"]=="YES" ? true : false;
      _bRecurringSub = widget.contactInfo["recurring_become"]=="YES" ? true : false;
    });
  }
  void saveContact(BuildContext context){
    if(_txtName.text==""){
      showErrorToast("Please fill name");
    }else if(_txtEmail.text==""){
      showErrorToast("Please fill email");
    }else if(_txtCreatedAt.text==""){
      showErrorToast("Please select created at");
    }else{
      if(widget.contactInfo == null){
        final body = {
          "user_id": widget.userInfo.id,
          "name": _txtName.text.trim(),
          "email": _txtEmail.text.trim(),
          "phone": _txtPhone.text.trim(),
          "address": _txtAddress.text.trim(),
          "notes": _txtNotes.text.trim(),
          "created_at": _txtCreatedAt.text.trim(),
          "new_subscriber": _bNewSub ? "YES": "NO",
          "cancel_subscriber": _bCancelSub ? "YES": "NO",
          "recurring_become": _bRecurringSub ? "YES": "NO"
        };
        setState(() {
          _progressBarActive = true;
        });
        ApiService.saveContact(body).then((response) {
          if (response != null && response["status"]) {
            showSuccessToast("Saved Contact");
            cancelContact();
          }else{
            showErrorToast("Already registered email");
          }
          setState(() {
            _progressBarActive = false;
          });
        });
      }else{
        final body = {
          "id": widget.contactInfo["id"],
          "user_id": widget.userInfo.id,
          "name": _txtName.text.trim(),
          "email": _txtEmail.text.trim(),
          "phone": _txtPhone.text.trim(),
          "address": _txtAddress.text.trim(),
          "notes": _txtNotes.text.trim(),
          "created_at": _txtCreatedAt.text.trim(),
          "new_subscriber": _bNewSub ? "YES": "NO",
          "cancel_subscriber": _bCancelSub ? "YES": "NO",
          "recurring_become": _bRecurringSub ? "YES": "NO"
        };
        setState(() {
          _progressBarActive = true;
        });
        ApiService.updateContact(body).then((response) {
          if (response != null && response["status"]) {
            showSuccessToast("Saved Contact");
            Navigator.of(context).pop();
          }else{
            showErrorToast("Already registered email");
          }
          setState(() {
            _progressBarActive = false;  
          });
        });
      }
      
    }
  }
  void cancelContact(){
    _txtName.text = "";
    _txtEmail.text = "";
    _txtPhone.text = "";
    _txtAddress.text = "";
    _txtNotes.text = "";
    _txtCreatedAt.text = format.format(now);
    setState(() {
      _bNewSub = true;
      _bCancelSub = false;
      _bRecurringSub = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    
    final nameRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: TextField(
        style: normalStyle,
        keyboardType: TextInputType.text,
        decoration: new InputDecoration(labelText: 'Name',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtName,
      ),
    );
    final emailRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: TextField(
        style: normalStyle,
        keyboardType: TextInputType.emailAddress,
        decoration: new InputDecoration(labelText: 'Email',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtEmail,
      ),
    );
    final phoneRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: TextField(
        style: normalStyle,
        keyboardType: TextInputType.phone,
        decoration: new InputDecoration(labelText: 'Phone',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtPhone,
      ),
    );
    final addressRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: TextField(
        style: normalStyle,
        keyboardType: TextInputType.text,
        decoration: new InputDecoration(labelText: 'Address',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtAddress,
      ),
    );
    final notesRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: TextField(
        maxLines: 4,
        style: normalStyle,
        keyboardType: TextInputType.multiline,
        decoration: new InputDecoration(labelText: 'Notes',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        controller: _txtNotes,
      ),
    );
    final createdAtRow = Padding(
      padding: EdgeInsets.fromLTRB(30.0, 6.0, 30.0, 0.0),
      child: DateTimeField(
        format: format,
        controller: _txtCreatedAt,
        decoration: InputDecoration(labelText: 'Created at',contentPadding: EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),),
        onShowPicker: (context, currentValue) {
          return showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
        },
      ),
    );
    final switchRow = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 0.0),
          child: Switch(
            value: _bNewSub,
            onChanged: (value) {
              setState(() {
                _bNewSub = value;
                if(value){
                  _bCancelSub = false;
                }else{
                  _bCancelSub = true;
                }
              });
            },
            activeTrackColor: Colors.lightBlueAccent, 
            activeColor: Colors.blue,
          )
        ),
        Text("New Subscriber"),
        Padding(
          padding: EdgeInsets.all(0.0),
          child: Switch(
            value: _bCancelSub,
            onChanged: (value) {
              setState(() {
                _bCancelSub = value;
                if(value){
                  _bNewSub = false;
                }else{
                  _bNewSub = true;
                }
              });
            },
            activeTrackColor: Colors.lightBlueAccent, 
            activeColor: Colors.blue,
          )
        ),
        Text("Cancelled"),
        Padding(
          padding: EdgeInsets.only(left: 0.0),
          child: Switch(
            value: _bRecurringSub,
            onChanged: (value) {
              setState(() {
                _bRecurringSub = value;
              });
            },
            activeTrackColor: Colors.lightBlueAccent, 
            activeColor: Colors.blue,
          )
        ),
        Text("Recurring"),
      ]
    );
    final btnRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(50.0),
            child: FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              splashColor: Colors.blueAccent,
              onPressed: () {
                saveContact(context);
              },
              child: Text(
                "Save",
                style: normalStyle,
              ),
            ),
          )
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(50.0),
            child: FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              splashColor: Colors.blueAccent,
              onPressed: () {
                if(widget.contactInfo == null){
                  cancelContact();
                }else{
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Cancel",
                style: normalStyle,
              ),
            ),
          )
        ),
      ],
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: widget.contactInfo != null? const Text("Edit Contact"): const Text("Add Contact"),),
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(height: 30.0,),
                Center(
                  child: Column(
                    children: <Widget>[
                      nameRow,
                      emailRow,
                      phoneRow,
                      addressRow,
                      notesRow,
                      switchRow,
                      createdAtRow,
                      btnRow                    
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
import 'package:flutter/material.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/widgets/drawer_widget.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class SubscriberScreen extends StatefulWidget {
  final UserInfo userInfo;
  SubscriberScreen({Key key, @required this.userInfo}) : super(key: key);
  @override
  _SubscriberScreenState createState() => _SubscriberScreenState();
}

class _SubscriberScreenState extends State<SubscriberScreen>{
  List<dynamic> filteredSubs = new List<dynamic>();
  TextEditingController txtSearch = TextEditingController();
  List<dynamic> allSubs;
  bool _progressBarActive = false;
  @override
  void initState(){
    super.initState();
    final body = {
      "user_id": widget.userInfo.id,
    };
    setState(() {
      _progressBarActive = true;
    });
    ApiService.getSubscribers(body).then((response) {
      setState(() {
        allSubs = response;
        _progressBarActive = false;
      });
      filterSearchResults(txtSearch.text);
    });
  }
  void filterSearchResults(String query) {
    if(query.isNotEmpty) {
      List<dynamic> dummyListData = List<dynamic>();
      allSubs.forEach((item) {
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
        filteredSubs.addAll(allSubs);
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opt-in Subscriber"),),
      drawer: AppDrawer(userInfo: widget.userInfo,),
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          ),
      ),
    );
  }
}
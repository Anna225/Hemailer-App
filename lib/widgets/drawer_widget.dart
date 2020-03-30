import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/screens/chat/chat_screen.dart';
import 'package:hemailer/screens/chat/onlinechat_screen.dart';
import 'package:hemailer/screens/contacts/contacts_screen.dart';
import 'package:hemailer/screens/dashboard_screen.dart';
import 'package:hemailer/screens/reminder_screen.dart';
import 'package:hemailer/screens/subscriber_screen.dart';
import 'package:hemailer/screens/users/users_screen.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:image_picker/image_picker.dart';

class AppDrawer extends StatefulWidget {
  final UserInfo userInfo;
  AppDrawer({Key key, @required this.userInfo}) : super(key: key);
  @override
  _AppDrawerState createState() => _AppDrawerState();
  
}

class _AppDrawerState extends State<AppDrawer>{
  String photoURL = "";
  UserInfo currentUserInfo;
  void initState(){
    super.initState();
    setState(() {
      currentUserInfo = widget.userInfo;
      photoURL = widget.userInfo.photoURL;
    });
  }
  Widget _createDrawerItem(
    {IconData icon, String text, GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }
  Future getImage() async {
    var file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file != null){
      String base64Image = base64Encode(file.readAsBytesSync());
      String fileName = file.path.split("/").last;
      String extension = fileName.split(".").last;
      final body = {
        "user_id": widget.userInfo.id,
        "extension": extension,
        "img_data": base64Image,
        
      };
      ApiService.uploadProfileImage(body).then((response) {
        if (response != null && response["status"]) {
          setState(() {
            var rng = new Random();
            photoURL = response["photo_url"] + "?v=" + rng.nextInt(100).toString();
            currentUserInfo.photoURL = photoURL;
          });
          
        }else{
          showErrorToast("Something error");
        }
      });
    }
    
    
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
          
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(widget.userInfo.userName),
              accountEmail: Text(widget.userInfo.userEmail),
              currentAccountPicture: InkWell(
                onTap: (){
                  getImage();
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(photoURL == "" ? baseURL + 'uploads/avatar/profile.jpg' : baseURL + photoURL ),
                ),
              ),
              
            ),
            _createDrawerItem(icon: Icons.dashboard,text: 'Dashboard',
              onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/home'), builder: (context) => new HomeScreen(userInfo:currentUserInfo))),
            ),
            _createDrawerItem(icon: Icons.contacts,text: 'Contacts',
              onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/contacts'), builder: (context) => new ContactsScreen(userInfo:currentUserInfo))),  
            ),
            _createDrawerItem(icon: Icons.alarm,text: 'Note Reminder',
              onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/reminder'), builder: (context) => new ReminderScreen(userInfo:currentUserInfo))),  
            ),
            Visibility(
              visible: widget.userInfo.optForm == "YES" ? true : false,
              child:_createDrawerItem(icon: Icons.notification_important,text: 'New Subscribers',
                  onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/subscribers'), builder: (context) => new SubscriberScreen(userInfo:currentUserInfo))),  
              ),
            ),
            Visibility(
              visible: widget.userInfo.chatOn == "YES" ? true : false,
              child: _createDrawerItem(icon: Icons.chat, text: 'Chat',
                onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/chat'), builder: (context) => new ChatScreen(userInfo:currentUserInfo))),  
              ),
            ),
            Visibility(
              visible: widget.userInfo.onlineChatOn == "YES" ? true : false,
              child: _createDrawerItem(icon: Icons.chat, text: 'Online Chat',
                onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/onlinechat'), builder: (context) => new OnlineChatScreen(userInfo:currentUserInfo))),  
              ),
            ),
            Visibility(
              visible: widget.userInfo.userLevel != "User" ? true : false,
              child: _createDrawerItem(icon: Icons.group, text: 'Registered Users',
                onTap: () => Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/users'), builder: (context) => new UsersScreen(userInfo:currentUserInfo))),  
              ),
            ),
            _createDrawerItem(icon: Icons.exit_to_app, text: 'Exit App',
              onTap: (){
                exit(0);
              }
            ),
          ],
        ),
      );
  }
}
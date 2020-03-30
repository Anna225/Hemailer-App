
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:hemailer/data/user_model.dart';
import 'package:hemailer/screens/dashboard_screen.dart';
import 'package:hemailer/screens/reset_password_screen.dart';
import 'package:hemailer/utils/rest_api.dart';
import 'package:hemailer/utils/utils.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>{
  
  TextEditingController _txtUserName = new TextEditingController();
  TextEditingController _txtPassword = new TextEditingController();
  bool _progressBarActive = false;
  @override
  Widget build(BuildContext context) {
    final usernameField = TextField(
      controller: _txtUserName,
      obscureText: false,
      style: normalStyle,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "User Name",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );
    final passwordField = TextField(
      controller: _txtPassword,
      obscureText: true,
      style: normalStyle,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Password",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );
    final loginButon = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Color(0xff4285f4),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () {
         
          if(_txtPassword.text.isEmpty || _txtUserName.text.isEmpty){
            showErrorToast("Please fill username and password");
          }else{
            final body = {
              "username": _txtUserName.text.trim(),
              "password": _txtPassword.text.trim(),
            };
            setState(() {
              _progressBarActive = true;
            });
            ApiService.login(body).then((response) {
              setState(() {
                _progressBarActive = false;
              });
              if (response != null && response["status"]) {
                var userInfo = response["user_info"];
                print(userInfo);
                UserInfo userSelInfo = new UserInfo(userInfo["id"], userInfo["username"], userInfo["email"], userInfo["level"], userInfo["phone"], userInfo["user_id"], userInfo["photo_url"], 
                userInfo["chat_on"], userInfo["onlinechat_on"], userInfo["optin_form"], userInfo["sales_funnel"], userInfo["contracts_sign"], userInfo["invoice_on"],
                userInfo["email_change"], userInfo["self_destruct"]);
                Navigator.of(context).pushReplacement(new MaterialPageRoute(settings: const RouteSettings(name: '/home'), builder: (context) => new HomeScreen(userInfo:userSelInfo)));
              }else{
                showErrorToast("Please fill correct username and password");
              }
            });
          }
          
        },
        child: Text("Login",
            textAlign: TextAlign.center,
            style: normalStyle.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
    final resetPasswordButon = Material(
      elevation: 1.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Color(0xff28a745),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(),
            ),
          );
        },
        child: Text("Forget Password",
            textAlign: TextAlign.center,
            style: normalStyle.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
    return Scaffold(
      // appBar: AppBar(title: const Text("Login Page"),),
      
      body: ModalProgressHUD(
        inAsyncCall: _progressBarActive,
        child:Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 155.0,
                      child: Image.asset(
                        "assets/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 45.0),
                    usernameField,
                    SizedBox(height: 25.0),
                    passwordField,
                    SizedBox(
                      height: 35.0,
                    ),
                    loginButon,
                    SizedBox(
                      height: 12.0,
                    ),
                    resetPasswordButon,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

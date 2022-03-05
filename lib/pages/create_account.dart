import 'dart:async';

import 'package:flutter/material.dart';
import './widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String username = "";

  submit() {
    if (username.length >= 3)
      Navigator.pop(context, username);
    else
      fun();
  }

  fun() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("Error",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              content: Text("Username requires min 3 characters",
                  style: TextStyle(fontSize: 17, color: Colors.white)),
            ));
  }

  @override
  Widget build(BuildContext parentContext) {
    return WillPopScope(
        child: Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context,
              titleText: "Set up your profile", removeBackButton: true),
          body: ListView(
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 25.0),
                      child: Center(
                        child: Text(
                          "Create a username",
                          style: TextStyle(
                              fontSize: 25.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Container(
                        child: Form(
                          child: TextFormField(
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                            onChanged: (val) => username = val,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 1.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 1.0),
                              ),
                              labelText: "Username",
                              labelStyle: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.black54,
                                  fontFamily: "Poppins-Regular"),
                              hintText: "Enter Username",
                              hintStyle: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.black54,
                                  fontFamily: "Poppins-Regular"),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: submit,
                      child: Container(
                        height: 50.0,
                        width: 350.0,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        child: Center(
                          child: Text(
                            "Submit",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        // ignore: missing_return
        onWillPop: () {
          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                    title: new Text("Alert",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    content: Text("Please enter a valid username",
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ));
        });
  }
}

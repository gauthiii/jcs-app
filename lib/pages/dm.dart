import 'package:flutter/material.dart';
import 'package:Joint/pages/widgets/header.dart';

class Dm extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: header(context, isAppTitle: true),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.chat,
              size: 300,
              color: Colors.black,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "JC MESSENGER IS STILL A WORK IN PROGRESS",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: "Bangers",
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        )));
  }
}

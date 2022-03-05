import 'package:Joint/pages/home.dart';
import 'package:Joint/pages/widgets/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/dm.dart';

class Logged extends StatefulWidget {
  @override
  Loggedx createState() => Loggedx();
}

class Loggedx extends State<Logged> {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: header(context,
            titleText: "Hello ${currentUser.displayName.split(" ")[0]}"),
        /*  appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            "HELLO ${list[0].toString().toUpperCase() + " " + list[1].toString().toUpperCase()}!!!",
            style: TextStyle(
                fontSize: ((list[0].toString().toUpperCase() +
                                " " +
                                list[1].toString().toUpperCase())
                            .length <=
                        30)
                    ? 18.0
                    : 13.0,
                fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Dm()),
                );
              },
              child: Icon(
                Icons.mail_outline,
                color: Colors.white,
              ),
            ),
          ],
        ),*/
        body: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Center(
                    child: Text("WELCOME TO",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black))),
                Center(
                    child: Text("The  Joint  Club",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "MrDafoe",
                            fontWeight: FontWeight.bold,
                            fontSize: 60,
                            color: Colors.black))),
                Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("\n",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.black)),
                          Text(
                              "Social Networking App with Face Authentication Security",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                          Text("First Release : 10 Jan 2021",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                          Text("Latest Release : 21 Feb 2022",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                          Text("Release Version : 1.0.5",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                          Text("Frontend : Flutter",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                          Text("Backend : Firebase,NodeJs and TensorFlow",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black)),
                        ])),
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.home,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Timeline",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.notifications_active,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Notifs",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Upload",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.search,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Search",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.mail,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Inbox",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.account_circle,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 30,
                                  color: Colors.black,
                                )),
                            Expanded(
                                flex: 1,
                                child: Text("Profile",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black))),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                      ]),
                ),
                Center(
                    child: Text("\nApp Developed By: Gauthiii's Applications",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black))),
              ],
            )));
  }
}

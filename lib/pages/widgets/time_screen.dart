import 'package:Joint/pages/models/fid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/widgets/header.dart';
import 'package:Joint/pages/widgets/progress.dart';

import '../post.dart';
import '../home.dart';
import '../upload.dart';

class TimeScreen extends StatefulWidget {
  @override
  _TimeScreen createState() => _TimeScreen();
}

class _TimeScreen extends State<TimeScreen> {
  List<Post> posts = [];
  bool isTLoading = false;
  List<DocumentSnapshot> ds = [];
  Fid followId;

  @override
  void initState() {
    super.initState();

    getProfilePosts();
  }

  getProfilePosts() async {
    if (this.mounted) {
      setState(() {
        posts = [];
        ds = [];
        isTLoading = true;
      });
    }

    DocumentSnapshot d = await timeRef.document(currentUser.id).get();
    if (!d.exists) {
      timeRef.document(currentUser.id).setData({
        "Ids": [],
      });
    }
    followId = Fid.fromDocument(d);

    if (followId.fid.length > 0)
      for (int i = 0; i < followId.fid.length; i++) {
        QuerySnapshot snapshot = await postsRef
            .document(followId.fid[i])
            .collection('userPosts')
            .orderBy('timestamp', descending: true)
            .getDocuments();

        snapshot.documents.forEach((d) {
          ds.add(d);
          Post x = Post.fromDocument(d);

          if (this.mounted) {
            setState(() {
              posts.add(x);
            });
          }
        });
      }

    if (this.mounted) {
      setState(() {
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        isTLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isTLoading) {
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, isAppTitle: true),
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 300,
                color: Colors.black,
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "YOUR TIMELINE IS LOADING....",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Bangers",
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              circularProgress()
            ],
          )));
    } else if (posts.length == 0)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, isAppTitle: true),
          body: RefreshIndicator(
              onRefresh: () {
                getProfilePosts();
              },
              child: ListView(children: [
                Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          size: 300,
                          color: Colors.black,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: Text(
                            "NO POSTS!!!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "Bangers",
                                fontSize: 50.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ))
              ])));
    else
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, isAppTitle: true),
          body: RefreshIndicator(
            onRefresh: () {
              getProfilePosts();
            },
            child: ListView(children: posts),
          ));
  }
}

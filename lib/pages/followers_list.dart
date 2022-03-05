import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/profile.dart';
import 'package:Joint/pages/widgets/header.dart';
import './models/user.dart';
import './home.dart';
import './widgets/progress.dart';
import 'models/Ids.dart';

class Follower extends StatefulWidget {
  String profileId;

  Follower({this.profileId});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Follower> {
  bool isloading = false;
  Id a;

  List<User> u = [];

  @override
  void initState() {
    super.initState();

    getFid();
  }

  User userx;
  getFid() async {
    setState(() {
      isloading = true;
    });

    DocumentSnapshot d2 = await usersRef.document(widget.profileId).get();
    userx = User.fromDocument(d2);

    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    snapshot.documents.forEach((doc) async {
      a = Id.fromDocument(doc);

      setState(() {
        print(a.id);
      });
      DocumentSnapshot doc1 = await usersRef.document(a.id).get();
      User user = User.fromDocument(doc1);
      setState(() {
        print(user.displayName);
      });

      u.add(user);
    });

    setState(() {
      isloading = false;
    });
  }

  buildSearchResults() {
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/5.png"),
          ),
        ),
        child: ListView(
            children: List.generate(u.length, (index) {
          return Container(
            color: Theme.of(context).primaryColor.withOpacity(0.7),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () => showProfile(context, profileId: u[index].id),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25.0,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(u[index].photoUrl),
                    ),
                    title: Text(
                      u[index].displayName,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      u[index].username,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Divider(
                  height: 2.0,
                  color: Colors.white54,
                ),
              ],
            ),
          );
        })));
  }

  @override
  Widget build(BuildContext context) {
    if (userx == null)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, titleText: "Followers"),
          body: circularProgress());

    if (u.length == 0)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, titleText: "Followers"),
          body: circularProgress());
    return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: header(context, titleText: "${userx.username} : Followers"),
        body: buildSearchResults());
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/home.dart';
import 'package:Joint/pages/models/Ids.dart';
import 'package:Joint/pages/models/user.dart';
import 'package:Joint/pages/profile.dart';
import 'package:Joint/pages/widgets/header.dart';
import 'package:Joint/pages/widgets/progress.dart';

class Likes extends StatefulWidget {
  final List<String> likes;

  Likes({this.likes});
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Likes> {
  bool isloading = false;
  Id a;

  List<User> u = [];

  @override
  void initState() {
    super.initState();

    getFid();
  }

  getFid() {
    widget.likes.forEach((val) async {
      print(val);

      setState(() {
        isloading = true;
      });
      DocumentSnapshot doc = await usersRef.document(val).get();
      User user = User.fromDocument(doc);

      setState(() {
        u.add(user);
      });
    });

    setState(() {
      isloading = false;
    });
  }

  Center buildNoContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.thumb_down,
            size: 250,
            color: Colors.black,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text(
              "Nobody's liked this post!!!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontFamily: "Bangers",
                fontSize: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
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
    if (u.length == 0)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: header(context, titleText: "Likes"),
          body: circularProgress());

    return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: header(context, titleText: "Likes"),
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

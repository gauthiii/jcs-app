import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/Logged.dart';
import 'package:Joint/pages/following_list.dart';
import 'package:Joint/pages/post.dart';
import 'package:Joint/pages/widgets/post_tile.dart';
import './models/user.dart';
import './models/fid.dart';
import './home.dart';
import './widgets/header.dart';
import './edit_profile.dart';
import './widgets/progress.dart';
import 'followers_list.dart';

class Profile2 extends StatefulWidget {
  final String profileId;

  Profile2({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile2> {
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  bool isFollowing = false;
  int isFirst = 0;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  Fid fid;
  User d;
  String x = "";
  bool isEdit = false;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController unController = TextEditingController();

  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;
  bool _unValid = true;

  @override
  void initState() {
    super.initState();
    getD();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
    getUser();
  }

  getUser() async {
    DocumentSnapshot doc = await usersRef.document(currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    unController.text = user.username;
    setState(() {
      isLoading = false;
    });
  }

  getD() async {
    DocumentSnapshot doc = await usersRef.document(widget.profileId).get();
    d = User.fromDocument(doc);
    setState(() {
      x = d.username;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  editProfile() {
    setState(() {
      isEdit = true;
    });
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.black,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Account Settings", function: editProfile);
    }
    if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: () {
          handleUnfollowUser();
          setState(() {
            followerCount -= 1;
          });
          /*   Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );

          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                    title: new Text("UNFOLLOWED!!!!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "JustAnotherHand",
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                  ));*/
        },
      );
    }
    if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: () {
          handleFollowUser();
          setState(() {
            followerCount += 1;
          });

          /*   Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );

          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                    title: new Text("FOLLOWING!!!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "JustAnotherHand",
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                  ));*/
        },
      );
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    removeToTimeline();
  }

  removeToTimeline() async {
    print(currentUserId);
    DocumentSnapshot doc = await timeRef.document(currentUserId).get();

    fid = Fid.fromDocument(doc);

    setState(() {
      fid.fid.remove(widget.profileId);
    });

    timeRef
        .document(currentUserId)
        .setData({"Ids": FieldValue.arrayUnion(fid.fid)});
  }

  List<String> f = [];

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({"id": currentUserId});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({"id": widget.profileId});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": timestamp,
    });

    addToTimeline();
  }

  addToTimeline() async {
    print(currentUserId);
    DocumentSnapshot doc = await timeRef.document(currentUserId).get();

    if (!doc.exists) {
      setState(() {
        f.add(widget.profileId);
      });

      timeRef
          .document(currentUserId)
          .setData({"Ids": FieldValue.arrayUnion(f)});
    } else {
      fid = Fid.fromDocument(doc);

      setState(() {
        fid.fid.add(widget.profileId);
      });

      timeRef
          .document(currentUserId)
          .setData({"Ids": FieldValue.arrayUnion(fid.fid)});
    }
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  postCount.toString(),
                                  style: TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "posts",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            FlatButton(
                                splashColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.7),
                                onPressed: () {
                                  if (followerCount == 0)
                                    showDialog(
                                        context: context,
                                        builder: (_) => new AlertDialog(
                                              title: new Text("NO FOLLOWERS!!!",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          "JustAnotherHand",
                                                      fontSize: 30.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white)),
                                              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                                            ));
                                  else
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Follower(
                                          profileId: widget.profileId,
                                        ),
                                      ),
                                    );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      followerCount.toString(),
                                      style: TextStyle(
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "followers",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                            FlatButton(
                                splashColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.7),
                                onPressed: () {
                                  if (followingCount == 0)
                                    showDialog(
                                        context: context,
                                        builder: (_) => new AlertDialog(
                                              title: new Text(
                                                  "NOT FOLLOWING ANYONE!!!",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          "JustAnotherHand",
                                                      fontSize: 30.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white)),
                                              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                                            ));
                                  else
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Following(
                                          profileId: widget.profileId,
                                        ),
                                      ),
                                    );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      followingCount.toString(),
                                      style: TextStyle(
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "following",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isLoading) {
      return circularProgress();
    } else if (!isFollowing && !isProfileOwner) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              size: 250,
              color: Colors.black,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Center(
                  child: Text(
                "PROFILE LOCKED!!!",
                style: TextStyle(
                  fontFamily: "Bangers",
                  color: Colors.black,
                  fontSize: 50.0,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
          ],
        ),
      );
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 250,
              color: Colors.black,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts!!!!!",
                style: TextStyle(
                  fontFamily: "Bangers",
                  color: Colors.black,
                  fontSize: 60.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 0,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  Column buildUserName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: unController,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            hintText: "Update Username",
            errorText: _unValid ? null : "Display Name too short",
            labelText: "Username",
            labelStyle: TextStyle(
                fontSize: 15.0,
                color: Colors.black54,
                fontFamily: "Poppins-Regular"),
          ),
        )
      ],
    );
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: displayNameController,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name too short",
            labelText: "Display Name",
            labelStyle: TextStyle(
                fontSize: 15.0,
                color: Colors.black54,
                fontFamily: "Poppins-Regular"),
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: bioController,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            hintText: "Update Bio",
            errorText: _bioValid ? null : "Bio too long",
            labelText: "Display Bio",
            labelStyle: TextStyle(
                fontSize: 15.0,
                color: Colors.black54,
                fontFamily: "Poppins-Regular"),
          ),
        )
      ],
    );
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
      unController.text.trim().length < 3 || unController.text.isEmpty
          ? _unValid = false
          : _unValid = true;
    });

    if (_displayNameValid && _bioValid && _unValid) {
      usersRef.document(currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text,
        "username": unController.text,
      });
    }

    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              backgroundColor: Colors.white,
              title: new Text("PROFILE UPDATED!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "JustAnotherHand",
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
            ));

    setState(() {
      isEdit = false;
    });
    getUser();
    setState(() {
      x = user.username;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (x == null || user == null)
      return circularProgress();
    else if (isEdit == false)
      return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: AppBar(
          centerTitle: true,
          title: Text((currentUserId == widget.profileId) ? user.username : x,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
        ),
        body: ListView(
          children: <Widget>[
            buildProfileHeader(),
            Divider(
              color: Colors.black,
            ),
            buildTogglePostOrientation(),
            Divider(
              color: Colors.black,
            ),
            buildProfilePosts(),
          ],
        ),
      );
    else if (isEdit == true)
      return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Edit Profile",
            style: TextStyle(),
          ),
        ),
        body: isLoading
            ? circularProgress()
            : ListView(
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: GestureDetector(
                            child: CircleAvatar(
                              radius: 50.0,
                              backgroundImage:
                                  CachedNetworkImageProvider(user.photoUrl),
                            ),
                            onTap: () {},
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              buildDisplayNameField(),
                              buildBioField(),
                              buildUserName(),
                            ],
                          ),
                        ),
                        RaisedButton(
                          color: Colors.black,
                          onPressed: updateProfileData,
                          child: Text(
                            "Update Profile",
                            style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 12.0),
                            child: Text(
                              "",
                              style: TextStyle(color: Colors.grey),
                            )),
                        GestureDetector(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image(
                                image: AssetImage('images/close.png'),
                                width: 64,
                                height: 64,
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                child: Text("No Changes",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Poppins-Regular")),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              isEdit = false;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
      );
  }
}

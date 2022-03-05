import 'dart:async';

import 'package:Joint/pages/chat_box.dart';
import 'package:Joint/pages/show_profile_posts.dart';
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
import 'activity_feed.dart';
import 'models/nick.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  Nick nickname;
  bool isLoading = false;
  bool fLoader = false;
  bool isFollowing = false;
  bool isRequested = false;
  bool isRequested2 = false;
  int isFirst = 0;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  Fid fid;
  User d;
  String x = "";
  bool isEdit = false;
  bool isOff = false;

  TextEditingController nickC = TextEditingController();

  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController unController = TextEditingController();

  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;
  bool _unValid = true;
  bool isLock;

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

  checkIfRequested() async {
    DocumentSnapshot d = await reqRef.document(widget.profileId).get();

    if (!d.exists) {
      reqRef.document(widget.profileId).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });

      d = await reqRef.document(widget.profileId).get();
    }

    Req req = Req.fromDocument(d);
    var flag = 0;
    req.follow.forEach((r) {
      print(r["id"]);
      if (r["id"] == currentUser.id) flag = 1;
    });

    setState(() {
      if (flag == 1)
        isRequested = true;
      else
        isRequested = false;
    });
  }

  checkIfRequested2() async {
    DocumentSnapshot d = await reqRef.document(currentUser.id).get();

    if (!d.exists) {
      reqRef.document(currentUser.id).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });

      d = await reqRef.document(currentUser.id).get();
    }

    Req req = Req.fromDocument(d);
    var flag = 0;
    req.follow.forEach((r) {
      print(r["id"]);
      if (r["id"] == widget.profileId) flag = 1;
    });

    setState(() {
      if (flag == 1)
        isRequested2 = true;
      else
        isRequested2 = false;
    });
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
    setState(() {
      isLoading = true;
      x = null;
      isLock = currentUser.isLock;
    });
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

    print("is followng? : ${doc.exists}");

    if (doc.exists) {
      DocumentSnapshot doc1 = await nickRef.document(currentUser.id).get();

      print("loading nick");

      if (!doc1.exists) {
        nickRef.document(currentUser.id).setData({'nicknames': {}});

        doc1 = await nickRef.document(currentUser.id).get();
      }

      setState(() {
        if (doc1.exists) {
          nickname = Nick.fromDocument(doc1);

          if (nickname.nicknames[widget.profileId] != null)
            nickC.text = nickname.nicknames[widget.profileId];
        }
      });
    }
    checkIfRequested();
    checkIfRequested2();
    setState(() {
      isFollowing = doc.exists;
      fLoader = false;
    });
  }

  getFollowers() async {
    setState(() {
      fLoader = true;
    });
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
              color: isFollowing
                  ? Colors.black
                  : (isRequested ? Colors.black : Colors.white),
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing
                ? Colors.white
                : (isRequested ? Colors.white : Colors.black),
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
    if (isFollowing == true) {
      return buildButton(
        text: "Unfollow",
        function: () {
          setState(() {
            fLoader = true;
          });
          handleUnfollowUser();
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
    } else if (isRequested == true) {
      return buildButton(
        text: "Requested",
        function: () {
          setState(() {
            fLoader = true;
            removeReq();
            getFollowers();
            getFollowing();
            checkIfFollowing();
            checkIfRequested();
          });
        },
      );
    } else if (isFollowing == false && isRequested == false) {
      return buildButton(
        text: "Follow",
        function: () {
          setState(() {
            fLoader = true;
            handleFollowUser();
            getFollowers();
            getFollowing();
            checkIfFollowing();
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

  removeReq() async {
    DocumentSnapshot d = await reqRef.document(widget.profileId).get();

    if (!d.exists) {
      reqRef.document(widget.profileId).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });

      d = await reqRef.document(widget.profileId).get();
    }

    Req req = Req.fromDocument(d);
    var y = {};
    req.follow.forEach((r) {
      print(r["id"]);
      if (r["id"] == currentUser.id) y = r;
    });

    req.follow.remove(y);

    reqRef.document(widget.profileId).updateData({"follow": req.follow});

    setState(() {
      isRequested = false;
    });
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
        getFollowers();
        getFollowing();
        checkIfFollowing();
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

        getFollowers();
        getFollowing();
        checkIfFollowing();
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

  handleFollowUser() async {
    Map x = {"id": currentUser.id, "request": "requested"};

    DocumentSnapshot d = await reqRef.document(widget.profileId).get();

    if (!d.exists) {
      reqRef.document(widget.profileId).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });

      d = await reqRef.document(widget.profileId).get();
    }

    Req req = Req.fromDocument(d);
    var flag = 0;
    req.follow.forEach((r) {
      print(r["id"]);
      if (r["id"] == currentUser.id) flag = 1;
    });

    if (flag == 0) req.follow.add(x);

    reqRef.document(widget.profileId).updateData({"follow": req.follow});

    /*
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
    */
  }

  addToTimeline() async {
    print(currentUserId);
    DocumentSnapshot doc = await timeRef.document(widget.profileId).get();

    if (!doc.exists) {
      setState(() {
        f.add(currentUser.id);
      });

      timeRef
          .document(widget.profileId)
          .setData({"Ids": FieldValue.arrayUnion(f)});
    } else {
      fid = Fid.fromDocument(doc);

      setState(() {
        fid.fid.add(currentUser.id);
      });

      timeRef
          .document(widget.profileId)
          .setData({"Ids": FieldValue.arrayUnion(fid.fid)});
    }
  }

  accreq(usn, photo) async {
    //Remove that request from ur req collection

    DocumentSnapshot d = await reqRef.document(currentUser.id).get();

    if (!d.exists) {
      reqRef.document(currentUser.id).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });

      d = await reqRef.document(currentUser.id).get();
    }

    Req req = Req.fromDocument(d);
    var y = {};
    req.follow.forEach((r) {
      print(r["id"]);
      if (r["id"] == widget.profileId) y = r;
    });

    req.follow.remove(y);

    reqRef.document(currentUser.id).updateData({"follow": req.follow});

    setState(() {
      isRequested2 = false;
    });

    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .document(currentUserId)
        .collection('userFollowers')
        .document(widget.profileId)
        .setData({"id": widget.profileId});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .document(currentUserId)
        .setData({"id": currentUserId});

    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(currentUserId)
        .collection('feedItems')
        .document(widget.profileId)
        .setData({
      "type": "follow",
      "ownerId": currentUserId,
      "username": usn,
      "userId": widget.profileId,
      "userProfileImg": photo,
      "timestamp": DateTime.now(),
      "isSeen": false,
    });

    addToTimeline();
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
          padding: EdgeInsets.only(top: 8.0),
        ),
        TextField(
          controller: unController,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            errorText: _unValid ? null : "Display Name too short",
            labelText: "Username",
            labelStyle: TextStyle(
                fontSize: 13.0,
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
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
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
                fontSize: 13.0,
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
          padding: EdgeInsets.only(top: 8.0),
        ),
        TextField(
          controller: bioController,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
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
                fontSize: 13.0,
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
        "isLock": isLock,
      });

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
    } else
      showDialog(
          context: context,
          builder: (_) => new AlertDialog(
                backgroundColor: Colors.white,
                title: new Text("Name/Username must be 3 characters",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "JustAnotherHand",
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
              ));
  }

  @override
  Widget build(BuildContext context) {
    if (isOff == true)
      return Scaffold(
        backgroundColor: Colors.orange[200],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(height: MediaQuery.of(context).size.height / 4.5),
            Container(
              padding: EdgeInsets.all(32),
              height: MediaQuery.of(context).size.height / 2,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/5.png"),
                ),
              ),
              alignment: Alignment.center,
            ),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                "Logged Out!!\nSwipe Left to Continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: "RussoOne",
                    color: Colors.black,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    else if (x == null || user == null)
      return circularProgress();
    else if (isEdit == false)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.black,
            title: (isRequested2 == false)
                ? Container(height: 0, width: 0)
                : Text(
                    user.displayName.split(" ")[0] + " wants to follow you\n",
                    style: TextStyle(
                        fontSize: 15.0,
                        fontFamily: "FredokaOne",
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[200])),
            actions: (isFollowing == false)
                ? []
                : [
                    IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange[200]),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (_) {
                                return AlertDialog(
                                  backgroundColor: Colors.black54,
                                  shape: RoundedRectangleBorder(
                                      side:
                                          BorderSide(color: Colors.orange[200]),
                                      borderRadius: BorderRadius.circular(20)),
                                  actions: [
                                    FlatButton(
                                      child: Text("Save",
                                          style: TextStyle(color: Colors.blue)),
                                      onPressed: () async {
                                        Navigator.pop(context);

                                        if (nickC.text.trim().isNotEmpty) {
                                          nickRef
                                              .document(currentUser.id)
                                              .updateData({
                                            'nicknames.${widget.profileId}':
                                                nickC.text.trim()
                                          });
                                        } else {
                                          showDialog(
                                              context: context,
                                              builder: (_) {
                                                return AlertDialog(
                                                  backgroundColor:
                                                      Colors.black54,
                                                  shape: RoundedRectangleBorder(
                                                      side: BorderSide(
                                                          color: Colors
                                                              .orange[200]),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  title: new Text(
                                                      "Nickname not changed\nMust contain atleast one character",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 20.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .orange[200])),
                                                );
                                              });
                                        }

                                        nickC.clear();

                                        getD();
                                        getProfilePosts();
                                        getFollowers();
                                        getFollowing();
                                        checkIfFollowing();

                                        getUser();
                                      },
                                    ),
                                    FlatButton(
                                      child: Text("Cancel",
                                          style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                  title: new Text(
                                      (nickname == null)
                                          ? "Enter Nickname"
                                          : "Change Nickname",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[200])),
                                  content: Container(
                                    height: 120,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Container(
                                            child: TextFormField(
                                              controller: nickC,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: InputDecoration(
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              20.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange[200],
                                                      width: 1),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              20.0)),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.orange[200]),
                                                ),
                                                labelText: "Nickname",
                                                labelStyle: TextStyle(
                                                    fontSize: 15.0,
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        })
                  ],
          ),
          body: RefreshIndicator(
            onRefresh: () {
              getD();
              getProfilePosts();
              getFollowers();
              getFollowing();
              checkIfFollowing();

              getUser();
            },
            child: Stack(children: [
              ListView(
                children: <Widget>[
                  FutureBuilder(
                      future: usersRef.document(widget.profileId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return circularProgress();
                        }
                        User user = User.fromDocument(snapshot.data);
                        return Column(
                          children: <Widget>[
                            ClipPath(
                              clipper: CurveClipper(),
                              child: Container(
                                color: Colors.black,
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                width: MediaQuery.of(context).size.width,
                                child: Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                            children: [
                                              (isRequested2 == false)
                                                  ? Container(
                                                      height: 0, width: 0)
                                                  : FlatButton(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: 4)),
                                                          Image(
                                                            image: AssetImage(
                                                                'images/close.png'),
                                                            width: 32,
                                                            height: 32,
                                                          ),
                                                          Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 10),
                                                            child: Text(
                                                                "Deny Request",
                                                                style: TextStyle(
                                                                    fontSize: 8,
                                                                    color: Colors
                                                                            .orange[
                                                                        200],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontFamily:
                                                                        "Poppins-Regular")),
                                                          ),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          4)),
                                                        ],
                                                      ),
                                                      onPressed: () {},
                                                    ),
                                              CircleAvatar(
                                                radius: 60.5,
                                                backgroundColor:
                                                    Colors.orange[200],
                                                child: CircleAvatar(
                                                  radius: 60,
                                                  backgroundColor: Colors.black,
                                                  child: CircleAvatar(
                                                    radius: 54.0,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                            user.photoUrl),
                                                  ),
                                                ),
                                              ),
                                              (isRequested2 == false)
                                                  ? Container(
                                                      height: 0, width: 0)
                                                  : FlatButton(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: 4)),
                                                          Image(
                                                            image: AssetImage(
                                                                'images/checked.png'),
                                                            width: 32,
                                                            height: 32,
                                                          ),
                                                          Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 10),
                                                            child: Text(
                                                                "Accept Request",
                                                                style: TextStyle(
                                                                    fontSize: 8,
                                                                    color: Colors
                                                                            .orange[
                                                                        200],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontFamily:
                                                                        "Poppins-Regular")),
                                                          ),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          4)),
                                                        ],
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          fLoader = true;
                                                          accreq(user.username,
                                                              user.photoUrl);
                                                          getD();
                                                          getProfilePosts();
                                                          getFollowers();
                                                          getFollowing();
                                                          checkIfFollowing();

                                                          getUser();
                                                        });
                                                      },
                                                    ),
                                            ],
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly),
                                        Padding(
                                            padding: EdgeInsets.only(top: 8)),
                                        Text(
                                            user.displayName +
                                                "${(nickname == null) ? "" : ((nickname.nicknames[widget.profileId] == null || nickname.nicknames[widget.profileId].length < 1) ? "" : "\n( ${nickname.nicknames[widget.profileId]} )")}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[200])),
                                        Padding(
                                            padding: EdgeInsets.only(top: 4)),
                                        Text(user.username,
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.orange[200])),
                                        Padding(
                                            padding: EdgeInsets.only(top: 32)),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              (fLoader)
                                                  ? Container(
                                                      alignment:
                                                          Alignment.center,
                                                      padding: EdgeInsets.only(
                                                          top: 10.0),
                                                      child:
                                                          CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation(
                                                                Colors.orange[
                                                                    200]),
                                                      ))
                                                  : FlatButton(
                                                      splashColor:
                                                          Theme.of(context)
                                                              .primaryColor
                                                              .withOpacity(0.7),
                                                      child: Column(children: [
                                                        Text(
                                                          followerCount
                                                              .toString(),
                                                          style: TextStyle(
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                        Text(
                                                          "Followers",
                                                          style: TextStyle(
                                                              fontSize: 12.0,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                      ]),
                                                      onPressed: () {
                                                        if (followerCount == 0)
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  new AlertDialog(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .black54,

                                                                    shape: RoundedRectangleBorder(
                                                                        side: BorderSide(
                                                                            color: Colors.orange[
                                                                                200]),
                                                                        borderRadius:
                                                                            BorderRadius.circular(20)),
                                                                    title: new Text(
                                                                        "NOT FOLLOWERS!!!",
                                                                        textAlign:
                                                                            TextAlign
                                                                                .center,
                                                                        style: TextStyle(
                                                                            fontFamily:
                                                                                "JustAnotherHand",
                                                                            fontSize:
                                                                                30.0,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.orange[200])),
                                                                    // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                                                                  ));
                                                        else
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      Follower(
                                                                profileId: widget
                                                                    .profileId,
                                                              ),
                                                            ),
                                                          );
                                                      }),
                                              (isFollowing == false &&
                                                      widget.profileId !=
                                                          currentUserId)
                                                  ? Container(
                                                      width: 0, height: 0)
                                                  : FlatButton(
                                                      splashColor:
                                                          Theme.of(context)
                                                              .primaryColor
                                                              .withOpacity(0.7),
                                                      child: Column(children: [
                                                        Text(
                                                          postCount.toString(),
                                                          style: TextStyle(
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                        Text(
                                                          "Posts",
                                                          style: TextStyle(
                                                              fontSize: 12.0,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                      ]),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    Show(
                                                              uid: user.id,
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                              (fLoader)
                                                  ? Container(
                                                      alignment:
                                                          Alignment.center,
                                                      padding: EdgeInsets.only(
                                                          top: 10.0),
                                                      child:
                                                          CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation(
                                                                Colors.orange[
                                                                    200]),
                                                      ))
                                                  : FlatButton(
                                                      splashColor:
                                                          Theme.of(context)
                                                              .primaryColor
                                                              .withOpacity(0.7),
                                                      child: Column(children: [
                                                        Text(
                                                          followingCount
                                                              .toString(),
                                                          style: TextStyle(
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                        Text(
                                                          "Following",
                                                          style: TextStyle(
                                                              fontSize: 12.0,
                                                              color: Colors
                                                                  .orange[200]),
                                                        ),
                                                      ]),
                                                      onPressed: () {
                                                        if (followingCount == 0)
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  new AlertDialog(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .black54,

                                                                    shape: RoundedRectangleBorder(
                                                                        side: BorderSide(
                                                                            color: Colors.orange[
                                                                                200]),
                                                                        borderRadius:
                                                                            BorderRadius.circular(20)),
                                                                    title: new Text(
                                                                        "NOT FOLLOWING ANYONE!!!",
                                                                        textAlign:
                                                                            TextAlign
                                                                                .center,
                                                                        style: TextStyle(
                                                                            fontFamily:
                                                                                "JustAnotherHand",
                                                                            fontSize:
                                                                                30.0,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.orange[200])),
                                                                    // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                                                                  ));
                                                        else
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      Following(
                                                                profileId: widget
                                                                    .profileId,
                                                              ),
                                                            ),
                                                          );
                                                      }),
                                            ]),
                                        Text("\n"),
                                      ]),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Image(
                                    image: AssetImage('images/5.png'),
                                    width: MediaQuery.of(context).size.height *
                                        0.18,
                                    height: MediaQuery.of(context).size.height *
                                        0.18,
                                  ),
                                  buildProfileButton(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                ],
              ),
              Container(
                  height: MediaQuery.of(context).size.height * 0.48,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: FloatingActionButton(
                          splashColor: Colors.white,
                          hoverColor: Colors.grey[900],
                          child: (widget.profileId != currentUser.id)
                              ? Icon(Icons.chat)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Padding(
                                          padding: EdgeInsets.only(left: 4)),
                                      Image(
                                        image: AssetImage('images/logout.png'),
                                        width: 30,
                                        height: 30,
                                      )
                                    ]),
                          backgroundColor: Colors.grey,
                          onPressed: () {
                            if (widget.profileId != currentUser.id)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(
                                      chatId: widget.profileId,
                                      proid: currentUserId),
                                ),
                              );
                            else
                              setState(() {
                                print("same id");

                                googleSignIn.signOut();
                                isAuth = false;
                                isOff = true;
                              });
                          },
                        ),
                      ),
                    ],
                  )),
            ]),
          ));
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
                            top: 8.0,
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
                          padding: EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 8),
                          child: Column(
                            children: <Widget>[
                              buildDisplayNameField(),
                              buildBioField(),
                              buildUserName(),
                            ],
                          ),
                        ),
                        ListTile(
                            leading: Icon(Icons.tag_faces, color: Colors.black),
                            title: Text(
                              "Enable Face-Lock",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            trailing: Switch(
                              value: isLock,
                              onChanged: (value) {
                                setState(() {
                                  isLock = !isLock;
                                });
                              },
                              activeTrackColor: Colors.lightBlueAccent[900],
                              activeColor: Colors.black,
                            )),
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
                              isLock = currentUser.isLock;
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

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    int curveHeight = 40;
    Offset controlPoint = Offset(size.width / 2, size.height + curveHeight);
    Offset endPoint = Offset(size.width, size.height - curveHeight);

    Path path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
          controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy)
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

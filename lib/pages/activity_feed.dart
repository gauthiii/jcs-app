import 'package:Joint/pages/widgets/custom_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/post_screen.dart';
import 'package:Joint/pages/profile.dart';
import 'package:Joint/pages/widgets/header.dart';
import 'package:Joint/pages/widgets/progress.dart';

import 'package:timeago/timeago.dart' as timeago;

import 'home.dart';
import 'models/user.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  Req req;
  bool isNotif = true;
  bool isLoading = false;
  List<ActivityFeedItem> feedItems = [];
  List<User> reqs = [];
  getActivityFeed() async {
    setState(() {
      isLoading = true;
      feedItems = [];
      reqs = [];
    });

    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();

    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
      // print('Activity Feed Item: ${doc.data}');
    });

    getReq();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    getActivityFeed();
  }

  getReq() async {
    DocumentSnapshot d = await reqRef.document(currentUser.id).get();
    if (!d.exists) {
      reqRef.document(currentUser.id).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });
    }
    req = Req.fromDocument(d);

    if (req.follow.isNotEmpty) {
      req.follow.forEach((r) async {
        print(r['id']);
        DocumentSnapshot doc = await usersRef.document(r['id']).get();
        User u = User.fromDocument(doc);

        setState(() {
          reqs.add(u);
        });
      });
    }
  }

  notif() {
    return Container(
        height: MediaQuery.of(context).size.height * 0.73,
        child: (feedItems.length == 0)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications_off,
                    size: 250,
                    color: Colors.black,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text(
                      "YOU DON'T HAVE ANY NOTIFICATIONS!!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 50.0,
                      ),
                    ),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: () async {
                  getActivityFeed();
                },
                child: ListView.separated(
                    itemCount: feedItems.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        Container(height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      configureMediaPreview() {
                        if (feedItems[index].type == 'like') {
                          return " liked your post";
                        } else if (feedItems[index].type == 'follow') {
                          return " is following you";
                        } else if (feedItems[index].type == 'comment') {
                          return ' replied: ${feedItems[index].commentData}';
                        } else {
                          return " Error: Unknown type '${feedItems[index].type}'";
                        }
                      }

                      showPost(context) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PostScreen(
                                    postId: feedItems[index].postId,
                                    userId: feedItems[index].postOwnerId)));
                      }

                      return Padding(
                          padding: EdgeInsets.only(
                              left: 16, right: 16, top: 1, bottom: 1),
                          child: GestureDetector(
                            onTap: () {
                              if (feedItems[index].type == 'follow')
                                showProfile(context,
                                    profileId: feedItems[index].userId);
                              else
                                showPost(context);
                            },
                            child: Card(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
                              child: ListTile(
                                title: RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: feedItems[index].username,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: configureMediaPreview(),
                                        ),
                                      ]),
                                ),
                                leading: GestureDetector(
                                  onTap: () => showProfile(context,
                                      profileId: feedItems[index].userId),
                                  child: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                        feedItems[index].userProfileImg),
                                  ),
                                ),
                                subtitle: Text(
                                  timeago.format(
                                      feedItems[index].timestamp.toDate()),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: (feedItems[index].type != "follow")
                                    ? GestureDetector(
                                        onTap: () => showPost(context),
                                        child: cachedNetworkImage(
                                            feedItems[index].mediaUrl),
                                      )
                                    : Container(height: 0, width: 0),
                              ),
                            ),
                          ));
                    })));
  }

  follow() {
    return Container(
        height: MediaQuery.of(context).size.height * 0.73,
        child: (reqs.length == 0)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.group_add,
                    size: 250,
                    color: Colors.black,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text(
                      "YOU DON'T HAVE ANY REQUESTS!!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 50.0,
                      ),
                    ),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: () async {
                  getActivityFeed();
                },
                child: ListView.separated(
                    itemCount: reqs.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        Container(height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                          padding: EdgeInsets.only(
                              left: 16, right: 16, top: 1, bottom: 1),
                          child: GestureDetector(
                            onTap: () {
                              showProfile(context, profileId: reqs[index].id);
                            },
                            child: Card(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
                              child: Column(children: [
                                ListTile(
                                  title: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: reqs[index].username,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: " wants to follow you",
                                          ),
                                        ]),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                        reqs[index].photoUrl),
                                  ),
                                  subtitle: Text(
                                    "Click to view profile",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ),
                          ));
                    }),
              ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[200],
      appBar: header(context, titleText: (isNotif) ? "Notifs" : "Requests"),
      body: RefreshIndicator(
        onRefresh: () async {
          getActivityFeed();
        },
        child: (isLoading)
            ? circularProgress()
            : ListView(children: [
                Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: ListTile(
                        leading: Icon(
                            (isNotif)
                                ? Icons.group_add
                                : Icons.notifications_active,
                            color: Colors.black),
                        title: Text(
                          (isNotif) ? "View Requests" : "View Notifs",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        onTap: () {
                          setState(() {
                            isNotif = !isNotif;
                          });
                        },
                        trailing: Switch(
                          value: isNotif,
                          onChanged: (value) {
                            setState(() {
                              isNotif = !isNotif;
                              print(isNotif);
                            });
                          },
                          activeTrackColor: Colors.lightBlueAccent[900],
                          activeColor: Colors.black,
                        ))),
                ((isNotif) ? notif() : follow())
              ]),
      ),
    );
  }
}

class ActivityFeedItem {
  final String username;
  final String userId;
  final String postOwnerId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;
  final bool isSeen;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.postOwnerId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
    this.isSeen,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
        username: doc['username'],
        userId: doc['userId'],
        postOwnerId: doc['postOwnerId'],
        type: doc['type'],
        postId: doc['postId'],
        userProfileImg: doc['userProfileImg'],
        commentData: doc['commentData'],
        timestamp: doc['timestamp'],
        mediaUrl: doc['mediaUrl'],
        isSeen: doc['isSeen']);
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

class Req {
  final List<dynamic> follow;
  final List<dynamic> share_p;
  final List<dynamic> transfer_p;

  Req({this.follow, this.share_p, this.transfer_p});

  factory Req.fromDocument(DocumentSnapshot doc) {
    return Req(
        follow: doc['follow'],
        share_p: doc['share_p'],
        transfer_p: doc['transfer_p']);
  }
}

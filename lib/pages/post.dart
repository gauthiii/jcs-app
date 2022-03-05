import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/comments.dart';
import 'package:Joint/pages/profile.dart';
import 'package:Joint/pages/upload.dart';
import 'package:Joint/pages/widgets/custom_image.dart';
import '../like_list.dart';
import 'package:uuid/uuid.dart';
import './models/user.dart';
import './timeline.dart';
import './widgets/progress.dart';
import 'home.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final Timestamp timestamp;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.timestamp,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        timestamp: this.timestamp,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final Timestamp timestamp;
  final String mediaUrl;
  bool showHeart = false;
  bool showHate = false;
  int likeCount;
  Map likes;
  bool isLiked;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.timestamp,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  List<Comment> comments = [];
  bool isCL = false;
  bool isComm = false;

  @override
  void initState() {
    super.initState();

    commentget();
  }

  commentget() async {
    setState(() {
      isCL = true;
      comments = [];
    });

    QuerySnapshot snapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .orderBy("timestamp", descending: false)
        .getDocuments();

    setState(() {
      snapshot.documents.forEach((d) {
        comments.add(Comment.fromDocument(d));
        print(Comment.fromDocument(d).comment);
      });

      isCL = false;
    });
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(
            location,
            style: TextStyle(color: Colors.white54),
          ),
          trailing: GestureDetector(
            onTap: () {
              if (likeCount == 0)
                showDialog(
                    context: context,
                    builder: (_) => new AlertDialog(
                          title: new Text("NO LIKES!!!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: "JustAnotherHand",
                                  fontSize: 30.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                        ));
              else {
                List<String> x = [];
                likes.keys.forEach((val) {
                  x.add(val);
                });

                for (int i = 0; i < x.length; i++) {
                  if (likes[x[i]] == false) x.remove(x[i]);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Likes(
                      likes: x,
                    ),
                  ),
                );
              }
            },
            child: Column(children: [
              Padding(padding: EdgeInsets.only(top: 8)),
              Container(
                  height: 35,
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red[900],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 28.0,
                          color: Colors.white,
                        ),
                        Text(
                          "$likeCount",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ])),
              ClipPath(
                clipper: CustomTriangleClipper(),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    if (ownerId == currentUserId) {
                      deletePost();

                      fun();
                    } else
                      fun1();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  fun1() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("THIS   AIN'T   YOUR   ACCOUNT!!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "JustAnotherHand",
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
            ));
  }

  fun() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("POST DELETED!!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "JustAnotherHand",
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
            ));
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    // delete post itself
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete uploaded image for thep ost
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
        showHate = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHate = false;
        });
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    DateTime ts = DateTime.now();
    bool isNotPostOwner = currentUserId != ownerId;
    //  if (isNotPostOwner)
    {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username +
            ((likeCount == 0) ? "" : " and $likeCount others"),
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postOwnerId": ownerId,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": ts,
        "isSeen": false,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800], width: 2)),
        child: cachedNetworkImage(mediaUrl),
      ),
    )

        /*      
    showHeart
              ? Icon(
                  Icons.thumb_up,
                  size: 180.0,
                  color: Colors.white,
                )
              : Text(""),
          showHate
              ? Icon(
                  Icons.thumb_down,
                  size: 180.0,
                  color: Colors.white,
                )
              : Text(""),
              
          */
        ;
  }

  giveTime(y) {
    var x1 = y.substring(0, 2);
    var x2 = y.substring(2, 5);
    var x3 = " AM";
    if (int.parse(x1) > 12) {
      var a = int.parse(x1) - 12;
      x1 = a.toString();
      x3 = " PM";
    }

    return x1 + x2 + x3;
  }

  giveDate(timestamp) {
    var z = timestamp.toDate().toString();
    var x1 = timestamp.toDate().toString().substring(0, 10).split("-");
    var y = x1[2] + "/" + x1[1] + "/" + x1[0];
    var time = giveTime(z.substring(11, 16));

    return y + " at " + time;
  }

  buildPostFooter() {
    return (description.trim().length < 1)
        ? Container(
            padding: EdgeInsets.only(bottom: 2.0, left: 20, right: 20, top: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              "Posted ${(timeago.format(timestamp.toDate()))}",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          )
        : Container(
            padding: EdgeInsets.only(bottom: 2.0),
            child: Column(
              children: <Widget>[
                FutureBuilder(
                    future: usersRef.document(ownerId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return circularProgress();
                      }
                      User user = User.fromDocument(snapshot.data);
                      return ListTile(
                        title: Text(
                          description,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Posted ${(timeago.format(timestamp.toDate()))}",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    }),
              ],
            ),
          );
  }

  buildC() {
    if (isCL == true)
      return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(top: 10.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ));
    else if (comments.isEmpty)
      return Container(height: 0);
    else
      return Column(
          children: List.generate(comments.length, (index) {
        return Column(children: [
          Padding(
            padding: EdgeInsets.only(bottom: 2.0),
            child: Container(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      comments[index].comment,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    leading: GestureDetector(
                      onTap: () => showProfile(context,
                          profileId: comments[index].userId),
                      child: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                            comments[index].avatarUrl),
                      ),
                    ),
                    subtitle: Text(
                      giveDate(comments[index].timestamp),
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    onLongPress: () {
                      if (comments[index].userId == currentUser.id)
                        handleDeletecom(context, comments[index].userId,
                            comments[index].cId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ]);
      }));
  }

  deletec(cId) {
    commentsRef
        .document(postId)
        .collection("comments")
        .document(cId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();

        setState(() {
          isComm = true;
        });

        commentget();
      }
    });
  }

  handleDeletecom(BuildContext parentContext, String userId, String cId) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this comment?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    if (currentUser?.id == userId) {
                      deletec(cId);
                      Navigator.pop(context);

                      showDialog(
                          context: parentContext,
                          builder: (_) => new AlertDialog(
                                title: new Text("COMMENT  DELETED!!!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: "JustAnotherHand",
                                        fontSize: 30.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                              ));
                    }
                    if (currentUser?.id != userId) {
                      Navigator.pop(context);

                      showDialog(
                          context: parentContext,
                          builder: (_) => new AlertDialog(
                                title: new Text("THIS  AIN'T  YOUR  COMMENT!!!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: "JustAnotherHand",
                                        fontSize: 30.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                              ));
                    }
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  TextEditingController commentController = TextEditingController();

  addComment() {
    DateTime ts = DateTime.now();
    String cId = Uuid().v4();
    commentsRef.document(postId).collection("comments").document(cId).setData({
      "cId": cId,
      "postId": postId,
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": ts,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });

    bool isNotPostOwner = ownerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(ownerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": ts,
        "postId": postId,
        "userId": currentUser.id,
        "postOwnerId": ownerId,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": mediaUrl,
        "isSeen": false,
      });
    }

    setState(() {
      cId = Uuid().v4();
      commentController.clear();
    });

    setState(() {
      isComm = true;
    });

    commentget();
  }

  buildPostButton() {
    return Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey[800], width: 2),
              left: BorderSide(color: Colors.grey[800], width: 2),
              right: BorderSide(color: Colors.grey[800], width: 2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          buildPostFooter(),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: handleLikePost,
                    child: Icon(
                      isLiked ? Icons.thumb_up_alt : Icons.thumb_up_off_alt,
                      size: 28.0,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isComm = !isComm;
                      });
                    },
                    child: Icon(
                      isComm ? Icons.speaker_notes_off : Icons.chat,
                      size: 28.0,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.share,
                      size: 28.0,
                      color: Colors.white,
                    ),
                  ),
                  /* Text(
                      "${giveDate(timestamp).split(" at ")[1]}\n${giveDate(timestamp).split(" at ")[0].substring(0, 6) + giveDate(timestamp).split(" at ")[0].substring(8)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white54)) */

                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.info_outlined,
                      size: 28.0,
                      color: Colors.white,
                    ),
                  ),
                ]),
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);

    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(children: <Widget>[
        Container(
            child: Card(
              color: Colors.black,
              child: Column(
                children: <Widget>[
                  buildPostHeader(),
                  buildPostImage(),
                  buildPostButton(),
                  (isComm) ? buildC() : Container(height: 0),
                  Text(""),
                  Padding(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: TextFormField(
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        controller: commentController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                            borderSide:
                                BorderSide(color: Colors.white, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          contentPadding: EdgeInsets.all(8),
                          hintText: "Write a Comment...",
                          hintStyle: TextStyle(
                              fontSize: 12.0,
                              color: Colors.white,
                              fontFamily: "Poppins-Regular"),
                          suffixIcon: GestureDetector(
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onTap: addComment,
                          ),
                        ),
                      )),
                  Text(""),
                ],
              ),
              elevation: 5.0,
            ),
            padding: EdgeInsets.all(10))
      ]),
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
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

class CustomTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

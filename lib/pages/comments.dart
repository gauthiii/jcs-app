import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/profile.dart';
import 'package:uuid/uuid.dart';
import './home.dart';
import './widgets/header.dart';
import './widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  String cId = Uuid().v4();

  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .document(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    DateTime ts = DateTime.now();
    commentsRef.document(postId).collection("comments").document(cId).setData({
      "cId": cId,
      "postId": postId,
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": ts,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });

    bool isNotPostOwner = postOwnerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": ts,
        "postId": postId,
        "userId": currentUser.id,
        "postOwnerId": postOwnerId,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": postMediaUrl,
      });
    }

    commentController.clear();
    setState(() {
      cId = Uuid().v4();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[200],
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(
            color: Colors.black,
            thickness: 2.0,
          ),
          ListTile(
            title: TextFormField(
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              controller: commentController,
              decoration: InputDecoration(
                  labelText: "Write a comment...",
                  labelStyle: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal)),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text(
                "Post",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  final String cId;
  final String postId;

  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
    this.cId,
    this.postId,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      postId: doc['postId'],
      cId: doc['cId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Theme.of(context).primaryColor.withOpacity(0.5),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                comment,
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              leading: GestureDetector(
                onTap: () => showProfile(context, profileId: userId),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(avatarUrl),
                ),
              ),
              subtitle: Text(
                timeago.format(timestamp.toDate()),
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              trailing: IconButton(
                onPressed: () => handleDeletecom(context),
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  deletec() {
    commentsRef
        .document(postId)
        .collection("comments")
        .document(cId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  fun(BuildContext parentContext) {
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

  fun1(BuildContext parentContext) {
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

  handleDeletecom(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this comment?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    if (currentUser?.id == userId) {
                      deletec();
                      Navigator.pop(context);
                      fun(context);
                    }
                    if (currentUser?.id != userId) {
                      Navigator.pop(context);
                      fun1(context);
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

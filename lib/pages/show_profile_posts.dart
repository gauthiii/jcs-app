import 'package:Joint/pages/post.dart';
import 'package:Joint/pages/widgets/post_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/widgets/header.dart';
import 'package:Joint/pages/widgets/progress.dart';

import 'home.dart';

class Show extends StatefulWidget {
  final String uid;
  Show({this.uid});

  @override
  _TimeScreen createState() => _TimeScreen();
}

class _TimeScreen extends State<Show> {
  List<Post> posts = [];
  bool isStart = true;
  bool isTLoading = false;
  List<DocumentSnapshot> ds = [];

  List<GridTile> gridTiles = [];

  @override
  void initState() {
    super.initState();

    getProfilePosts();
  }

  getProfilePosts() async {
    if (this.mounted) {
      setState(() {
        posts = [];
        gridTiles = [];
        isTLoading = true;
      });
    }

    QuerySnapshot snapshot = await postsRef
        .document(widget.uid)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    if (this.mounted) {
      setState(() {
        snapshot.documents.forEach((d) {
          ds.add(d);
          Post x = Post.fromDocument(d);

          posts.add(x);
        });

        posts.forEach((post) {
          gridTiles.add(GridTile(
              child: InkWell(
            child: PostTile(post),
            onLongPress: () {
              if (widget.uid == currentUser.id)
                handleDeletePost(context, post.postId, post.ownerId);
            },
          )));
        });

        isTLoading = false;
        //  posts = ds.map((doc) => Post.fromDocument(doc)).toList();
        if (widget.uid == currentUser.id && isStart == true && posts.length > 0)
          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                    backgroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.orange[200]),
                        borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      "Tap to View\nLong-Press to Delete",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[200]),
                    ),
                  ));

        isStart = false;
      });
    }
  }

  handleDeletePost(BuildContext parentContext, String postId, String ownerId) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);

                    deletePost(postId, ownerId);
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

  deletePost(postId, ownerId) async {
    // delete post itself
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
        getProfilePosts();
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

  @override
  Widget build(BuildContext context) {
    if (isTLoading) {
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "Profile Posts",
              style: TextStyle(),
            ),
          ),
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
                  "YOUR POSTS ARE LOADING....",
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
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "Profile Posts",
              style: TextStyle(),
            ),
          ),
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
          )));
    else
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "Profile Posts",
              style: TextStyle(),
            ),
          ),
          body: ListView(children: [
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: gridTiles,
            )
          ]));
  }
}

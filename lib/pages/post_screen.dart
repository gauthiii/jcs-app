import 'package:flutter/material.dart';
import './home.dart';
import './widgets/header.dart';
import './post.dart';
import './widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            backgroundColor: Colors.orange[200],
            appBar: header(context, titleText:"Post"),
            body: ListView(
              children: <Widget>[
                Container(
                 
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    ),
      );
    
  }
}

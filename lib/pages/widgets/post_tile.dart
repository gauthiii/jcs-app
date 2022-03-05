import 'package:flutter/material.dart';
import 'package:Joint/pages/widgets/custom_image.dart';

import '../post.dart';
import '../post_screen.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  @override
  Widget build(BuildContext context) {

     showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }
    return GestureDetector(
      onTap: () => showPost(context),
      child: Container(
    
        child:cachedNetworkImage(post.mediaUrl),) 
    );
  }
}

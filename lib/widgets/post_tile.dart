import 'package:flutter/material.dart';
import 'package:social_test/pages/single_post.dart';
import 'package:social_test/widgets/post.dart';

import 'custom_image.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      // child: cachedNetworkImage(post.mediaUrl),
      child: cachedNetworkImage("post.mediaUrl"),
    );
  }
}

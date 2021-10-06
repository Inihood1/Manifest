import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_test/widgets/header.dart';
import 'package:social_test/widgets/post.dart';
import 'package:social_test/widgets/progress.dart';

import 'home.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({required this.userId, required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data!);
        return Center(
          child: Scaffold(
            appBar: header(context, titleText: post.title),
            body: ListView(
              children: [
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

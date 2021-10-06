import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:social_test/widgets/header.dart';
import 'package:social_test/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'home.dart';

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  final String owner;

  Comments({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
    required this.owner,
  });

  @override
  CommentsState createState() => CommentsState(
      postId: this.postId,
      postOwnerId: this.postOwnerId,
      postMediaUrl: this.postMediaUrl,
      owner: this.owner);
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  bool isSwitched = false;
  var textValue = 'Comment anonymously: OFF';
  String isAnonymous = "";
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  final String owner;

  CommentsState({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
    required this.owner,
  });

  // display comment
  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .document(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data!.documents.forEach((doc) {
            // comments.clear();
            comments.add(Comment.fromDocument(doc));
          });

          if (comments.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat, color: Colors.grey),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: Text(
                        "Comments will appear here",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    if (commentController.text.isNotEmpty) {
      if (isSwitched == false) {
        //  print("Post anonymously: OFF");
        isAnonymous = "OFF";
      } else {
        //   print("Post anonymously: ON");
        isAnonymous = "ON";
      }

      commentsRef.document(postId).collection("comments").add({
        //"username": currentUser!.username,
        "username":
            isAnonymous == "ON" ? "Anonymous user" : currentUser!.username,
        "comment": commentController.text,
        "timestamp": Timestamp.now(),
        "avatarUrl": isAnonymous == "ON"
            ? "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/anonymouseuser.png?alt=media&token=f85fa846-4b69-4953-9078-cb0a2086d4b4"
            : currentUser!.photoUrl,
        "userId": currentUser!.id,
        "postId": postId
      });
      bool isNotPostOwner = postOwnerId != currentUser!.id;
      if (isNotPostOwner) {
        activityFeedRef.document(postOwnerId).collection('feedItems').add({
          "type": "comment",
          "commentData": commentController.text,
          "timestamp": Timestamp.now(),
          "postId": postId,
          "userId": owner,
          "commentOwner": currentUser!.id,
          "username":
              isAnonymous == "ON" ? "Anonymous user" : currentUser!.username,
          "userProfileImg": isAnonymous == "ON"
              ? "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/anonymouseuser.png?alt=media&token=f85fa846-4b69-4953-9078-cb0a2086d4b4"
              : currentUser!.photoUrl,
          "mediaUrl": postMediaUrl,
        });
      }
      commentController.clear();
    }
  }

  void toggleSwitch(bool value) {
    if (isSwitched == false) {
      setState(() {
        isSwitched = true;
        textValue = 'Comment anonymously: ON';
      });
      print('Switch Button is ON');
    } else {
      setState(() {
        isSwitched = false;
        textValue = 'Comment anonymously: OFF';
      });
      print('Switch Button is OFF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          Text(
            '$textValue',
            style: TextStyle(fontSize: 20),
          ),
          Switch(
              onChanged: toggleSwitch,
              value: isSwitched,
              activeColor: Theme.of(context).primaryColor),
          ListTile(
            title: TextFormField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              controller: commentController,
              decoration: InputDecoration(
                  labelText: "Write a comment...",
                  border: InputBorder.none,
                  fillColor: Color(0xfff3f3f4),
                  filled: false),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatefulWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  final String postId;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
    required this.postId,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      postId: doc['postId'],
    );
  }

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  @override
  Widget build(BuildContext context) {
    bool isPostOwner = currentUser!.id == widget.userId;
    return Column(
      children: [
        ListTile(
          trailing: isPostOwner
              ? Text("")
              : IconButton(
                  onPressed: () {
                    if (mounted) {
                      reportPost(context);
                    }
                  },
                  icon: Icon(Icons.more_vert),
                ),
          title: Text(
            widget.username,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(widget.avatarUrl),
          ),
          subtitle: Text(
            "${widget.comment}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("${timeago.format(widget.timestamp.toDate())}"),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }

  // handleDeletePost(BuildContext parentContext) {
  //   return showDialog(
  //       context: parentContext,
  //       builder: (context) {
  //         return SimpleDialog(
  //           title: Text("Remove this Report?"),
  //           children: [
  //             SimpleDialogOption(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   deleteComment();
  //                 },
  //                 child: Text(
  //                   'Delete',
  //                   style: TextStyle(color: Colors.red),
  //                 )),
  //             SimpleDialogOption(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: Text('Cancel')),
  //           ],
  //         );
  //       });
  // }

  showDeleteMessage() {
    Fluttertoast.showToast(
        msg: "Your comment is being deleted",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.deepOrange,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // deleteComment() async {
  //   //  print("owner id: $postOwner");
  //   showDeleteMessage();
  //   // delete post itself
  //   commentsRef
  //       .document(widget.postId)
  //       .collection('comment')
  //       .document(postId)
  //       .get()
  //       .then((doc) {
  //     if (doc.exists) {
  //       doc.reference.delete();
  //     }
  //   });
  // }

  reportPost(BuildContext context) {
    return showDialog(
        //  barrierColor: Colors.red,
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            elevation: 3,
            title: Text('Support'),
            content: Text("Do you think this is objectionable content?"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Report',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  startReporting(context);
                },
              ),
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  startReporting(BuildContext context) async {
    await reports
        .document(currentUser!.id)
        .collection(widget.postId)
        .document("comments")
        .collection("reports")
        .document("all reports")
        .setData({
      "postOwnerId": widget.userId,
      "postId": widget.postId,
      "timestamp": Timestamp.now(),
      "reporterAvatarUrl": currentUser!.photoUrl,
      "reporterID": currentUser!.id,
    }).whenComplete(() => showReportSuccessDialog());
  }

  showReportSuccessDialog() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 3,
            title: Text('Thank you for your report'),
            content: Text("We are always working "
                "hard to keep this community safe"),
            actions: [
              FlatButton(
                color: Colors.deepOrange,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  notifyUser();
                },
              ),
            ],
          );
        });
  }

  notifyUser() async {
    await activityFeedRef
        .document(currentUser!.id)
        .collection("feedItems")
        .add({
      "type": "admin_info",
      "info": "Your report is being reviewed",
      "username": "",
      "userId": widget.userId,
      "likeOwner": currentUser!.id,
      "userProfileImg":
          "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/logo.png?alt=media&token=4621d3d4-0c80-4156-bf8e-8a5fb53d1962",
      "postId": widget.postId,
      "timestamp": Timestamp.now(),
    });
    showReportMessage();
  }

  showReportMessage() {
    Fluttertoast.showToast(
        msg: "Thank you for your report",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.deepOrange,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:social_test/pages/activity_feed.dart';
import 'package:social_test/pages/comments.dart';
import 'package:social_test/pages/home.dart';
import 'package:social_test/pages/media_viewer.dart';
import 'package:social_test/pages/topics.dart';
import 'package:social_test/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post extends StatefulWidget {
  final String title;
  final String contact;
  final String reportForWho;
  final String isAnonymous;
  final String category;
  final String sub_loc;
  final String postId;
  final Timestamp timestamp;
  final Timestamp timestampOfReport;
  final String ownerId;
  final String postOwner;
  final String username;
  final String location;
  final String description;
  final dynamic likes;
  final List mediaUrl;

  Post({
    required this.title,
    required this.contact,
    required this.reportForWho,
    required this.isAnonymous,
    required this.category,
    required this.sub_loc,
    required this.postId,
    required this.timestamp,
    required this.timestampOfReport,
    required this.ownerId,
    required this.postOwner,
    required this.username,
    required this.location,
    required this.description,
    this.likes,
    required this.mediaUrl,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      title: doc['title'],
      contact: doc['contact'],
      reportForWho: doc['reportForWho'],
      isAnonymous: doc['isAnonymous'],
      category: doc['category'],
      sub_loc: doc['sub_loc'],
      postId: doc['postId'],
      timestamp: doc['timestamp'],
      timestampOfReport: doc['timestampOfReport'],
      ownerId: doc['ownerId'],
      postOwner: doc['postOwner'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'], // change to mediaUrl later
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
        title: this.title,
        contact: this.contact,
        reportForWho: this.reportForWho,
        isAnonymous: this.isAnonymous,
        category: this.category,
        sub_loc: this.sub_loc,
        postId: this.postId,
        timestamp: this.timestamp,
        timestampOfReport: this.timestampOfReport,
        ownerId: this.ownerId,
        postOwner: this.postOwner,
        username: this.username,
        location: this.location,
        description: this.description,
        likes: this.likes,
        mediaUrl: this.mediaUrl,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser!.id;
  final String title;
  final String contact;
  final String reportForWho;
  final String isAnonymous;
  final String category;
  final String sub_loc;
  final String postId;
  final Timestamp timestamp;
  final Timestamp timestampOfReport;
  final String ownerId;
  final String postOwner;
  final String username;
  final String location;
  final String description;
  bool showHeart = false;
  int likeCount;
  Map likes;
  List mediaUrl;
  late bool isLiked;
  List<String> commentCounts = [];

  _PostState({
    required this.title,
    required this.contact,
    required this.reportForWho,
    required this.isAnonymous,
    required this.category,
    required this.sub_loc,
    required this.postId,
    required this.timestamp,
    required this.timestampOfReport,
    required this.ownerId,
    required this.postOwner,
    required this.username,
    required this.location,
    required this.description,
    required this.likes,
    required this.likeCount,
    required this.mediaUrl,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: postTopicRef.document(ownerId).get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Topics topics = Topics.fromDocument(snapshot.data!);
        // User user = User.fromDocument(snapshot.data!);
        bool isPostOwner = currentUserId == postOwner;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(topics.icon),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: topics.name),
            child: InkWell(
              onTap: () {
                showProfile(context, profileId: topics.name);
              },
              child: Text("$category",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  )),
            ),

            // Text(
            //   "$category",
            //   style: TextStyle(
            //     color: Colors.black,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
          ),
          subtitle: Text('$location,  ${timeago.format(timestamp.toDate())}'),

          // trailing: IconButton(
          //   onPressed: () => handleDeletePost(context),
          //   icon: Icon(Icons.more_vert),
          // )

          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : IconButton(
                  onPressed: () => reportPost(context),
                  icon: Icon(Icons.more_vert),
                ),
        );
      },
    );
  }

  startReporting() async {
    // print("starting...");
    await reports
        .document(currentUser!.id)
        .collection(postId)
        .document("post")
        .collection("reports")
        .document("all reports")
        .setData({
      "postOwnerId": postOwner,
      "postId": postId,
      "timestamp": Timestamp.now(),
      "reporterAvatarUrl": currentUser!.photoUrl,
      "reporterID": currentUser!.id,
    }).whenComplete(() => showReportSuccessDialog());
    //  print("done");
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
      "userId": ownerId,
      "likeOwner": currentUser!.id,
      "userProfileImg":
          "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/logo.png?alt=media&token=4621d3d4-0c80-4156-bf8e-8a5fb53d1962",
      "postId": postId,
      "timestamp": Timestamp.now(),
    });
    showReportMessage();
  }

  // reportPost(BuildContext context) {
  //   return showDialog(
  //       context: context,
  //       builder: (context) {
  //         return SimpleDialog(
  //           title: Text(
  //             "Do you think this is an objectionable content?",
  //             style: TextStyle(fontSize: 15),
  //           ),
  //           children: [
  //             SimpleDialogOption(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   startReporting();
  //                 },
  //                 child: Text(
  //                   'Report post',
  //                   style: TextStyle(color: Colors.red),
  //                 )),
  //             SimpleDialogOption(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: Text('Cancel')),
  //           ],
  //         );
  //       });
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
                  'Report post',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  startReporting();
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

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this Report?"),
            children: [
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePost();
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

  showDeleteMessage() {
    Fluttertoast.showToast(
        msg: "Your post is being deleted",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.deepOrange,
        textColor: Colors.white,
        fontSize: 16.0);
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

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    //  print("owner id: $postOwner");
    showDeleteMessage();
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
    // delete from timeline
    timelineRef
        .document(postOwner)
        .collection('timelinePosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for the post
    storageRef.child("$postId").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(postOwner)
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

  // function for liking a post
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
    // print(postOwner);
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = currentUserId != postOwner;
    if (isNotPostOwner) {
      activityFeedRef
          .document(postOwner)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": "someone",
        "userId": ownerId,
        "likeOwner": currentUser!.id,
        "userProfileImg":
            "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/anonymouseuser.png?alt=media&token=f85fa846-4b69-4953-9078-cb0a2086d4b4",
        "postId": postId,
        "timestamp": Timestamp.now(),
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != postOwner;
    if (isNotPostOwner) {
      activityFeedRef
          .document(postOwner)
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

  // widget for showing the post image
  buildPostImage() {
    return GestureDetector(
      // onDoubleTap: handleLikePost,
      onTap: () {},
      child: Stack(
        // alignment: Alignment.center,
        children: [
          // cachedNetworkImage(mediaUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
            child: Column(
              children: [
                Text(
                  "$title",
                  //overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(height: 10.0),
                ExpandableText(
                  "$description",
                  animation: true,
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 7,
                  linkColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  getCommentsCount(String postId) async {
    QuerySnapshot snapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentCounts = snapshot.documents.map((doc) => doc.documentID).toList();
    if (mounted) {
      setState(() {
        commentCounts.length;
      });
    }
  }

  formatTime() {
    // DateTime _time =DateTime.parse(timestampOfReport.toDate().toString());
    //  return _time;

    var date = timestampOfReport.toDate();
    //  var output1 = DateFormat('MM/dd, hh:mm a').format(date); // 12/31, 10:00 PM
    var output2 = DateFormat.yMMMd().format(date); // Dec 31, 2000
    return output2;
  }

  buildPostFooter() {
    getCommentsCount(postId);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IntrinsicHeight(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    //  print("$mediaUrl");
                    showComments(context,
                        postId: postId,
                        ownerId: postOwner,
                        mediaUrl: "mediaUrl",
                        owner: ownerId);
                  },
                  child: new Padding(
                    padding: new EdgeInsets.all(10.0),
                    child: new Text(
                      "${commentCounts.length} comment(s)",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),

                VerticalDivider(),
                GestureDetector(
                  onTap: () => showComments(context,
                      postId: postId,
                      ownerId: postOwner,
                      mediaUrl: "mediaUrl",
                      owner: ownerId),
                  child: Icon(
                    Icons.chat,
                    size: 28.0,
                    color: Colors.blue[900],
                  ),
                ),
                VerticalDivider(),

                InkWell(
                  onTap: () {
                    //   print("$mediaUrl");
                    openMediaPage(context,
                        postId: postId, OwnerId: ownerId, mediaUrl: mediaUrl);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text("${mediaUrl.length} media file(s)"),
                  ),
                ),

                // Text("${mediaUrl.length} media file(s)", style: TextStyle(fontSize: 15),),
              ],
            ))
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "Sub location: ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Expanded(child: Text("$sub_loc"))
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "Reporting: $reportForWho",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: contact == ""
                  ? Text(
                      "No contact info",
                      style: TextStyle(
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      "Contact: $contact",
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "By: $username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "Date: ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Expanded(
                // child: Text("${formatTime()} (${timeago.format(timestampOfReport.toDate())})")
                child: Text("${formatTime()}"))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            IntrinsicHeight(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: handleLikePost,
                    child: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      size: 30.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Padding(padding: EdgeInsets.all(8.0)),
                  VerticalDivider(),
                  Text(
                    "$likeCount vote(s)",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 5,
          child: Column(
            children: [
              buildPostHeader(),
              buildPostImage(),
              Divider(),
              buildPostFooter(),
              Divider(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

openMediaPage(BuildContext context,
    {required String postId,
    required String OwnerId,
    required List<dynamic> mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return MediaViewer(
        postId: postId, postOwnerId: OwnerId, mediaUrl: mediaUrl);
  }));
}

showComments(BuildContext context,
    {required String postId,
    required String ownerId,
    required String mediaUrl,
    required String owner}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl,
        owner: owner);
  }));
}

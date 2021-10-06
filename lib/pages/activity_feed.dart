import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_test/pages/single_post.dart';
import 'package:social_test/widgets/header.dart';
import 'package:social_test/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'home.dart';
import 'non_user_profile.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
          child: StreamBuilder(
              stream: activityFeedRef
                  .document(currentUser!.id)
                  // .document("111905766962940450973")
                  .collection('feedItems')
                  .orderBy('timestamp', descending: true)
                  // .limit(50)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return circularProgress();
                }
                List<ActivityFeedItem> feedItems = [];
                snapshot.data!.documents.forEach((doc) {
                  feedItems.add(ActivityFeedItem.fromDocument(doc));
                });
                if (feedItems.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications, color: Colors.grey),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              "Notifications will appear here",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView(
                  children: feedItems,
                );
              })),
    );
  }
}

late Widget mediaPreview;
late String activityItemText; // summary for activity notification

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String info;
  final String userProfileImg;
  final String commentData;
  final String likeOwner;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    required this.postId,
    required this.info,
    required this.userProfileImg,
    required this.commentData,
    required this.likeOwner,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      info: doc['info'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      likeOwner: doc['likeOwner'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
          // userId: "Violence",
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                  // decoration: BoxDecoration(
                  //   image: DecorationImage(
                  //     fit: BoxFit.cover,
                  //    // image: CachedNetworkImageProvider(mediaUrl),
                  //   ),
                  // ),
                  )),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = "voted your report";
    } else if (type == 'admin_info') {
      activityItemText = "$info";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showPost(context),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {required String profileId}) {
  // print("profile id: $profileId");

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NonUserProfile(
        profileId: profileId,
      ),
    ),
  );
}

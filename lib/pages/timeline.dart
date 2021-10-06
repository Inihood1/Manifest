import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_test/models/user.dart';
import 'package:social_test/pages/search.dart';
import 'package:social_test/pages/topics.dart';
import 'package:social_test/widgets/header.dart';
import 'package:social_test/widgets/post.dart';
import 'package:social_test/widgets/progress.dart';

import 'home.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User? currentUser;
  final String orderBy;
  final bool keepAlive;

  Timeline(
      {required this.currentUser,
      required this.orderBy,
      required this.keepAlive});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline>
    with AutomaticKeepAliveClientMixin<Timeline> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<Post> postsList = [];
  // late QuerySnapshot snapshot;
  List<QuerySnapshot> itemsList = [];
  List<String> followingList = [];
  //bool keepAlive = true;
  ScrollController controller = ScrollController();
  //QuerySnapshot snapshot;

  @override
  void initState() {
    super.initState();
    getFirstList();
    controller.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      // print("at the end of list");
      fetchNextList();
    }
  }

  fetchNextList() async {
    // QuerySnapshot snapshot = await timelineRef
    //     .document(widget.currentUser!.id)
    //     .collection('timelinePosts')
    //     .orderBy('likes', descending: true)
    //     .limit(4)
    //     .startAfter(itemsList)
    //     //.startAfterDocument(documentList[documentList.length - 1])
    //     .getDocuments();
    // List<Post> posts =
    //     snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    // setState(() {
    //   // this.postsList.add(posts);
    //   // this.postsList.clear();
    //   this.postsList = posts;
    // });
  }

  closeKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser!.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  getFirstList() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser!.id)
        .collection('timelinePosts')
        .orderBy(widget.orderBy, descending: true)
        .where("status", isEqualTo: "approve")
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      // this.postsList.add(posts);
      this.postsList.clear();
      this.postsList = posts;
    });
    //  print("the full list: ${p.length}");
  }

  buildUsersToFollow() {
    // getNewState();
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () => getFirstList(),
      child: StreamBuilder(
        stream: postTopicRef.limit(10).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data!.documents.forEach((doc) {
            // User user = User.fromDocument(doc);
            Topics topics = Topics.fromDocument(doc);
            final bool isAuthUser = currentUser!.id == topics.name;
            final bool isFollowingUser = followingList.contains(topics.name);
            // remove auth user from recommended list
            if (isAuthUser) {
              return;
            } else if (isFollowingUser) {
              return;
            } else {
              UserResult userResult = UserResult(topics);
              userResults.add(userResult);
            }
          });
          return Container(
            color: Theme.of(context).accentColor.withOpacity(0.2),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Your timeline is empty, Please follow a topic",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 30.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(children: userResults),
              ],
            ),
          );
        },
      ),
    );
  }

//  bool get wantKeepAlive => widget.keepAlive;
  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);
    return Scaffold(
      appBar: header(context, isAppTitle: true, titleText: 'Timeline'),
      body: RefreshIndicator(
        onRefresh: () => getFirstList(),
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          controller: controller,
          addAutomaticKeepAlives: true,
          itemCount: postsList.length,
          itemBuilder: (context, index) {
            if (postsList == null) {
              return circularProgress();
            } else if (postsList.isEmpty) {
              return circularProgress();
            } else {
              return Padding(
                  padding: EdgeInsets.all(2), child: postsList[index]);
            }
          },
        ),
      ),
    );
  }
}

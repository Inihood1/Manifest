import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_test/models/user.dart';
import 'package:social_test/pages/edit_profile.dart';
import 'package:social_test/pages/home.dart';
import 'package:social_test/widgets/header.dart';
import 'package:social_test/widgets/post.dart';
import 'package:social_test/widgets/post_tile.dart';
import 'package:social_test/widgets/progress.dart';

class Profile extends StatefulWidget {
  //final String profileId;

  final String profileId;

  Profile({required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with AutomaticKeepAliveClientMixin<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser!.id;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  String postOrientation = "list";

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();

    // Timer(Duration(seconds: 4), () {
    //   getProfilePosts();
    //   // print("Yeah, this line is printed after 3 seconds");
    // });
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    // print("profile id: ${widget.profileId}");
    setState(() {
      isLoading = true;
    });
    // ini please, make a pagination to fewer post at a time
    QuerySnapshot snapshot = await timelineRef
        .document(widget.profileId)
        .collection('timelinePosts')
        .where("postOwner", isEqualTo: widget.profileId)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });

    // QuerySnapshot snapshot = await postsRef
    //     .document(widget.profileId)
    //     .collection('userPosts')
    //     .orderBy('timestamp', descending: true)
    //     .getDocuments();
    // setState(() {
    //   isLoading = false;
    //   postCount = snapshot.documents.length;
    //   posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    // });
  }

  Column buildCountColumn(String label, int count) {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return Column();
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }
  }

  // Column buildCountColumn1(String label, int count) {
  //   bool isProfileOwner = currentUserId == widget.profileId;
  //   if(isProfileOwner){
  //     return Column();
  //   }else{
  //     return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           count.toString(),
  //           style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
  //         ),
  //         Container(
  //           margin: EdgeInsets.only(top: 4.0),
  //           child: Text(
  //             label,
  //             style: TextStyle(
  //               color: Colors.grey,
  //               fontSize: 15.0,
  //               fontWeight: FontWeight.w400,
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  // }

  editProfile() {
    //print("edit profile button");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  SingleChildScrollView buildButton(
      {required String text, required Function function}) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(top: 2.0),
        child: TextButton(
          onPressed: () => function(),
          child: Container(
            width: 150.0,
            height: 27.0,
            child: Text(
              text,
              style: TextStyle(
                color: isFollowing ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFollowing ? Colors.white : Theme.of(context).accentColor,
              border: Border.all(
                color:
                    isFollowing ? Colors.grey : Theme.of(context).accentColor,
              ),
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }

  BuildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Edit Profile",
        function: editProfile,
      );
    } else if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: handleUnfollowUser,
      );
    } else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser!.username,
      "userId": currentUserId,
      "userProfileImg": currentUser!.photoUrl,
      "timestamp": timestamp,
    });
  }

  buildProfileHeaderCurrentUser() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      // future: postTopicRef.document(widget.profileId).get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data!);

        // Topics topics = Topics.fromDocument(snapshot.data!);

        // print(user.username);
        // print(user.displayName);
        // print(user);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            // buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            BuildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              // Container(
              //   alignment: Alignment.centerLeft,
              //   padding: EdgeInsets.only(top: 4.0),
              //   child: Text(
              //     user.displayName,
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              // Container(
              //   alignment: Alignment.centerLeft,
              //   padding: EdgeInsets.only(top: 2.0),
              //   child: Text(
              //     user.bio,
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  // building each profile post in grid and list form
  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/no_post.png', height: 260.0),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(Icons.grid_on),
          // add a color to whichever button is selected
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(Icons.list),
          // add a color to whichever button is selected
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID') ?? 0;
    if (userID != 0) {
      print(userID);
      return userID;
    }
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: [
          buildProfileHeaderCurrentUser(),
          // building the toggle buttons to toggle between grid and list view
          Divider(),
          //  buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}

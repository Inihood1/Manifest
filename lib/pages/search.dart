import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_test/pages/home.dart';
import 'package:social_test/pages/topics.dart';
import 'package:social_test/widgets/progress.dart';

import 'activity_feed.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Search for a topic...",
          filled: false,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      handleSearch(searchController.text);
    });
  }

  handleSearch(String query) {
    // ini please rebuild this query to ignore uppercase
    Future<QuerySnapshot> topics =
        postTopicRef.where("name", isGreaterThan: query).getDocuments();
    setState(() {
      searchResultsFuture = topics;
    });
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Image.asset(
              'assets/search.png',
              height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
            Text(
              "Find topics",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data!.documents.forEach((doc) {
          Topics topics = Topics.fromDocument(doc);
          UserResult searchResult = UserResult(topics);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final Topics topics;

  UserResult(this.topics);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => {
              //print(user.id)
              showProfile(context, profileId: topics.name)
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(topics.icon),
              ),
              // title: Text(
              //   user.displayName,
              //   style:
              //       TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              // ),
              title: Text(
                topics.name,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}

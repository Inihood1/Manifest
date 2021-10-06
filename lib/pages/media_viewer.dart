import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_test/widgets/header.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaViewer extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final List<dynamic> mediaUrl;

  MediaViewer(
      {required this.postId,
      required this.postOwnerId,
      required this.mediaUrl});

  @override
  _MediaViewerState createState() => _MediaViewerState(
      postId: this.postId,
      postOwnerId: this.postOwnerId,
      mediaUrl: this.mediaUrl);
}

class _MediaViewerState extends State<MediaViewer> {
  final String postId;
  final String postOwnerId;
  final List<dynamic> mediaUrl;

  _MediaViewerState({
    required this.postId,
    required this.postOwnerId,
    required this.mediaUrl,
  });

  String getFileName(String url) {
    RegExp regExp = new RegExp(r'.+(\/|%2F)(.+)\?.+');
    //This Regex won't work if you remove ?alt...token
    var matches = regExp.allMatches(url);
    var match = matches.elementAt(0);
    print("${Uri.decodeFull(match.group(2)!)}");
    return Uri.decodeFull(match.group(2)!);
  }

  launchURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  buildMedia() {
    if (mediaUrl.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_file, color: Colors.grey),
          Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: Text(
                  "Media files will appear here",
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
    } else {
      return ListView(
        children: mediaUrl
            .map(
              (url) => ElevatedButton(
                  onPressed: () {
                    launchURL(url);
                  },
                  child: Text(getFileName(url))),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Media files"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(child: buildMedia()),
              // Divider(),
              // Text('Test children widget', style: TextStyle(fontSize: 20),),
              // ListTile(
              //   title: TextFormField(
              //     keyboardType: TextInputType.multiline,
              //     maxLines: null,
              //     textCapitalization: TextCapitalization.sentences,
              //     controller: commentController,
              //     decoration: InputDecoration(labelText: "Write a comment..."),
              //   ),
              //   trailing: OutlineButton(
              //     onPressed: addComment,
              //     borderSide: BorderSide.none,
              //     child: Text("Post"),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_test/models/user.dart';
import 'package:social_test/pages/home.dart';
import 'package:social_test/widgets/progress.dart';
import 'package:uuid/uuid.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  FacebookLogin facebookLogin = FacebookLogin();
  User? user;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _displayNameValid = true;
  bool _bioValid = true;
  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  TextStyle linkStyle = TextStyle(
      color: Colors.blue, fontSize: 15.0, fontWeight: FontWeight.bold);
  TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 10.0);

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user!.displayName;
    bioController.text = user!.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          // child: Text(
          //   "Your display Name will not be shown when you report or comment on a crime",
          //   style: TextStyle(color: Colors.red),
          // )
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null : "Bio too long",
          ),
        )
      ],
    );
  }

  updateProfileData() async {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 20
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_displayNameValid) {
      setState(() {
        isLoading = true;
      });
      await handleSubmit();
      await usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
      });
      setState(() {
        isLoading = false;
      });
      SnackBar snackbar = SnackBar(content: Text("Profile updated!"));
      _scaffoldKey.currentState!.showSnackBar(snackbar);
    }
    await getUser();
  }

  Future<void> removeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userID');
    prefs.remove('type');
  }

  goHome() {
    // Navigator.push(context,
    //     MaterialPageRoute(builder: (context) => Home("likes", true)));

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home("likes", true)),
        ModalRoute.withName("/Home"));
  }

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('type') ?? 0;
    if (loginType.toString() == "g") {
      await googleSignIn.signOut();
      if (auth.currentUser() != null) {
        //  print("google account is not null");
        auth.signOut();
      }
      await removeAuth();
      goHome();
    } else if (loginType.toString() == "f") {
      await facebookLogin.logOut();
      if (auth.currentUser() != null) {
        // print("facebook account is not null");
        auth.signOut();
      }
      await removeAuth();
      goHome();
    } else if (loginType.toString() == "e") {
      // await facebookLogin.logOut();
      if (auth.currentUser() != null) {
        // print("facebook account is not null");
        auth.signOut();
      }
      await removeAuth();
      goHome();
    } else {
      //   print("command unknown");
    }
  }

  confirmLogout() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(''),
            content: Text("Are you sure to logout?"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  logout();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              size: 30.0,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user!.photoUrl),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: defaultStyle,
                          children: [
                            TextSpan(
                                text: 'click to change image',
                                style: linkStyle,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    selectImage(context);
                                  }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            // buildBioField(),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: () {
                            // logout();
                            confirmLogout();
                          },
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Change image"),
          children: [
            SimpleDialogOption(
                child: Text("From Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("From Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  handleSubmit() async {
    if (file != null) {
      await compressImage();
      String mediaUrl = await uploadImage(file);
      await createPostInFirestore(mediaUrl: mediaUrl);
    }
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file!.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child("${user!.id}.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({required String mediaUrl}) {
    usersRef.document(widget.currentUserId).updateData({"photoUrl": mediaUrl});
  }
}

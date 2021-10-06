import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:social_test/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';

class NewPost extends StatefulWidget {
  final User? currentUser;
  NewPost({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<NewPost>
    with AutomaticKeepAliveClientMixin<NewPost> {
  TextEditingController titleController = TextEditingController();
  TextEditingController explicitLocationController = TextEditingController();
  TextEditingController contactInfoController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  // TextEditingController locationController = TextEditingController();
  File? file;
  String isAnonymous = "";
  String category = "";
  String report_for_who = "";
  String location = "";
  double _progress = 0;
  DateTime selectedDate = DateTime.now();
  bool isUploading = false;
  bool iSFileReady = false;
  String postId = Uuid().v4();
  List<String> downloadedFileUrls = [];
  List<File> selectedFiles = [];
  bool isSwitched = false;
  int pageIndex = 0;
  var textValue = 'Post anonymously: OFF';
  bool _isLoading = false;
  final _sub_loc_form_key = GlobalKey<FormState>();
  final _contact_form_key = GlobalKey<FormState>();

  late PageController pageController;

  var crimeSelection = [
    "Ableism",
    "Assault or harassment",
    "Bribes",
    "Poor public service",
    "Tribalism",
    "Unsanitary conditions",
    "Non payment of salary",
    "Child abuse",
    "Stalking",
    "Violence",
    "Gender-based violence",
    "Sexual harassment",
    "Drug abuse",
    "Government corruption",
    "Other corrupt practices",
    "Others",
  ];

  var reportForWho = ["For self", "For someone"];

  var statesSelection = [
    "Abia",
    "Adamawa",
    "Akwa Ibom",
    'Anambra',
    "Bauchi",
    "Bayelsa",
    "Benue",
    "Borno",
    'Cross River',
    "Delta",
    "Ebonyi",
    "Edo",
    "Ekiti",
    'Enugu',
    "Gombe",
    "Imo",
    "Jigawa",
    "Kaduna",
    'Kano',
    "Katsina",
    "Kebbi",
    "Kogi",
    "Kwara",
    'Lagos',
    "Nasarawa",
    "Niger",
    "Ogun",
    "Ondo",
    'Osun',
    "Oyo",
    "Plateau",
    "Rivers",
    "Sokoto",
    'Taraba',
    "Yobe",
    "Zamfara",
    "FCT",
  ];

  showErrorDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Oops'),
            content:
                Text("Something is not right. Title, location, sub-location, "
                    "category, report person and date are mandatory fields"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
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

  showSuccessDialog() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 3,
            title: Text('Post added successfully!'),
            // content: Text(""),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  goHome();
                },
              ),
            ],
          );
        });
  }

  accountRestrictionDialog() {
    return showDialog(
        barrierColor: Colors.red,
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 3,
            title: Text('Your account is restricted'),
            content: Text("Some of your past reports have been "
                "flagged as inappropriate or abusive "
                "and so you have been disabled from "
                "posting and commenting till further notice"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Contact support',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  contactSupport();
                },
              ),
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
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

  contactSupport() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'inihood@gmail.com',
      query: 'subject=Account restriction&body=', //add subject and body here
    );
    var url = params.toString();
    await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }

  showInfoDialog() {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 3,
            title: Text('Support'),
            content: Text("Your contact info is required if you would like "
                "someone to reach you regarding your report. This field is optional"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  //goHome();
                },
              ),
            ],
          );
        });
  }

  getCategoryIcon(String category) async {
    String imgUrl =
        await postTopicRef.document(category).collection("icon").toString();
    return imgUrl;
  }

  createPostInFirestore(
      String contactinfo,
      String reportWho,
      String location,
      String subLoc,
      String description,
      String title,
      String category,
      List<String> downloadedFileUrls,
      DateTime selectedDate,
      String isAnonymous) async {
    String iconImg = await getCategoryIcon(category);

    await timelineRef
        .document(widget.currentUser!.id)
        .collection("timelinePosts")
        .document(postId)
        .setData({
      "postId": postId,
      "title": title,
      "category": category,
      "ownerId": category,
      "reportForWho": reportWho,
      "contact": contactinfo == null ? "" : contactinfo,
      //  "ownerId": widget.currentUser!.id,
      "postOwner": widget.currentUser!.id,
      //"username": widget.currentUser!.username,
      "username": isAnonymous,
      "isAnonymous": isAnonymous,
      "iconImg": iconImg,
      "status": "approve",
      "sub_loc": subLoc,
      "mediaUrl": downloadedFileUrls,
      "description": description,
      "location": location,
      "timestamp": Timestamp.now(),
      "timestampOfReport": selectedDate,
      "likes": {},
    }).onError((error, stackTrace) => {});

    await postsRef
        .document(category)
        .collection("userPosts")
        .document(postId)
        .setData({
          "postId": postId,
          "title": title,
          "category": category,
          "ownerId": category,
          "reportForWho": reportWho,
          "contact": contactinfo == null ? "" : contactinfo,
          //  "ownerId": widget.currentUser!.id,
          "postOwner": widget.currentUser!.id,
          //"username": widget.currentUser!.username,
          "username": isAnonymous,
          "isAnonymous": isAnonymous,
          "iconImg": iconImg,
          "status": "approve",
          "sub_loc": subLoc,
          "mediaUrl": downloadedFileUrls,
          "description": description,
          "location": location,
          "timestamp": Timestamp.now(),
          "timestampOfReport": selectedDate,
          "likes": {},
        })
        .whenComplete(() => {
              userPostsRef
                  .document(widget.currentUser!.id)
                  // .document(category)
                  .collection("posts")
                  .document(postId)
                  .setData({
                "postId": postId,
                "title": title,
                "category": category,
                "ownerId": category,
                "reportForWho": reportWho,
                "contact": contactinfo == null ? "" : contactinfo,
                //  "ownerId": widget.currentUser!.id,
                "postOwner": widget.currentUser!.id,
                //"username": widget.currentUser!.username,
                "username": isAnonymous,
                "isAnonymous": isAnonymous,
                "iconImg": iconImg,
                "status": "approve",
                "sub_loc": subLoc,
                "mediaUrl": downloadedFileUrls,
                "description": description,
                "location": location,
                "timestamp": Timestamp.now(),
                "timestampOfReport": selectedDate,
                "likes": {},
              })
            })
        .onError((error, stackTrace) => {});
  }

  void toggleSwitch(bool value) {
    if (isSwitched == false) {
      setState(() {
        isSwitched = true;
        textValue = 'Post anonymously: ON';
      });
      // print('Switch Button is ON');
    } else {
      setState(() {
        isSwitched = false;
        textValue = 'Post anonymously: OFF';
      });
      //  print('Switch Button is OFF');
    }
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2022),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Scaffold buildUploadForm() {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white70,
          // leading: IconButton(
          //     icon: Icon(Icons.arrow_back, color: Colors.black),
          //     onPressed: goHome()),
          title: Text(
            "Create a report",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (currentUser!.account_status == "red") {
                  accountRestrictionDialog();
                } else {
                  handleSubmit();
                }
              },
              child: Text(
                "Post",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: ListView(
            children: [
              Column(
                children: [
                  isUploading
                      ? LinearProgressIndicator(
                          color: Colors.deepPurple,
                          value: _progress,
                        )
                      : Text(""),
                  Container(
                    child: Center(
                        child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                            widget.currentUser!.photoUrl),
                      ),
                      title: Container(
                        // width: 250.0,
                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          maxLength: 70,
                          textCapitalization: TextCapitalization.sentences,
                          controller: titleController,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                          decoration: InputDecoration(
                            hintText: "Title of the report",
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.pin_drop,
                      color: Colors.orange,
                      size: 35.0,
                    ),
                    title: Container(
                      width: 250.0,
                      child: DropdownSearch<String>(
                        validator: (v) {},
                        mode: Mode.BOTTOM_SHEET,
                        showSelectedItem: true,
                        items: statesSelection,
                        label: "Where did it happen?",
                        hint: "Select state",
                        //  popupItemDisabled: (String s) => s.startsWith('I'),
                        onChanged: (v) {
                          setState(() {
                            location = v!;
                          });
                        },
                        // selectedItem: "Brazil"
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Text(""),
                    title: Container(
                      child: Form(
                        key: _sub_loc_form_key,
                        autovalidate: true,
                        child: TextFormField(
                          maxLength: 17,
                          controller: explicitLocationController,
                          // onSaved: (val) => explicit_location = val!,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Sub-location",
                            labelStyle: TextStyle(fontSize: 15.0),
                            hintText: "Type a specific location",
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.category,
                      color: Colors.orange,
                      size: 35.0,
                    ),
                    title: Container(
                      width: 100.0,
                      child: DropdownSearch<String>(
                        validator: (v) {
                          // print(v);
                          setState(() {
                            category = v!;
                          });
                        },
                        mode: Mode.BOTTOM_SHEET,
                        showSelectedItem: true,
                        items: crimeSelection,
                        label: "Select a crime or event topic",
                        hint: "Event topic",
                        //  popupItemDisabled: (String s) => s.startsWith('I'),
                        onChanged: (v) {
                          setState(() {
                            category = v!;
                          });
                        },
                        // selectedItem: "Brazil"
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.person_add,
                      color: Colors.orange,
                      size: 35.0,
                    ),
                    title: Container(
                      width: 100.0,
                      child: DropdownSearch<String>(
                        validator: (v) {
                          // print(v);
                          setState(() {
                            report_for_who = v!;
                          });
                        },
                        mode: Mode.MENU,
                        showSelectedItem: true,
                        items: reportForWho,
                        label: "Who are you reporting for",
                        hint: "Please select",
                        //  popupItemDisabled: (String s) => s.startsWith('I'),
                        onChanged: (v) {
                          setState(() {
                            report_for_who = v!;
                          });
                        },
                        // selectedItem: "Brazil"
                      ),
                    ),
                  ),
                  //  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, right: 2),
                    child: ListTile(
                      leading: Icon(
                        Icons.contact_mail,
                        color: Colors.orange,
                        size: 35.0,
                      ),
                      title: Form(
                        key: _contact_form_key,
                        child: TextFormField(
                          //maxLength: 17,
                          controller: contactInfoController,
                          // onSaved: (val) => explicit_location = val!,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                showInfoDialog();
                              },
                              icon: Icon(
                                Icons.contact_support,
                                color: Colors.blue,
                                size: 30.0,
                              ),
                            ),
                            border: OutlineInputBorder(),
                            labelText:
                                "Please provide a contact info(optional)",
                            labelStyle: TextStyle(fontSize: 13.0),
                            hintStyle: TextStyle(fontSize: 13.0),
                            hintText: "phone or email",
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 35.0,
                    ),
                    title: ElevatedButton(
                      onPressed: () {
                        _selectDate(context);
                      },
                      child: Text(
                        "When did it happen?",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.normal),
                      ),
                    ),
                    subtitle: Text(
                      "${selectedDate.toLocal()}".split(' ')[0],
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.normal),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Text(
                      '$textValue',
                      style: TextStyle(fontSize: 20),
                    ),
                    title: Switch(
                        onChanged: toggleSwitch,
                        value: isSwitched,
                        activeColor: Theme.of(context).primaryColor),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(top: 5.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0, left: 15.0),
                    child: TextFormField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      maxLength: 1500,
                      textCapitalization: TextCapitalization.sentences,
                      controller: descriptionController,
                      style: TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Describe your report",
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Divider(),
                  Container(
                    width: 200.0,
                    height: 80.0,
                    alignment: Alignment.center,
                    child: RaisedButton.icon(
                      label: Text(
                        iSFileReady ? "File(s) added" : "Add files",
                        style: TextStyle(color: Colors.white),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Colors.blue,
                      onPressed: getFiles,
                      icon: Icon(
                        Icons.perm_media_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  Future uploadMultipleImages() async {
    try {
      // setState(() {
      //   isUploading = true;
      // });
      for (int i = 0; i < selectedFiles.length; i++) {
        final StorageReference storageReference =
            FirebaseStorage().ref().child("$postId/${selectedFiles[i]}");

        final StorageUploadTask uploadTask =
            storageReference.putFile(selectedFiles[i]);
        //  print(" This is the file list ${_imageList[i]}");
        final StreamSubscription<StorageTaskEvent> streamSubscription =
            uploadTask.events.listen((event) {
          // print(" This is the progress: ${event.snapshot.bytesTransferred.toDouble() /
          //     event.snapshot.totalByteCount.toDouble()}");

          setState(() {
            _progress = event.snapshot.bytesTransferred.toDouble() /
                event.snapshot.totalByteCount.toDouble();
          });
          //  print('THIS IS THE EVENT TYPE: ${event.type}');
        });

        await uploadTask.onComplete;
        streamSubscription.cancel();

        String imageUrl = await storageReference.getDownloadURL();
        downloadedFileUrls.add(imageUrl); //all all the urls to the list
      }
      // await postsRef.document("user1").setData({
      //   "arrayOfImages": downloadedFileUrls,
      // });
      // setState(() {
      //   isUploading = false;
      //   postId = Uuid().v4();
      // });
    } catch (e) {
      //  print(e);
    }
  }

  getFiles() async {
    FilePickerResult result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      selectedFiles = result.paths.map((path) => File(path)).toList();
      setState(() {
        iSFileReady = true;
      });
    } else {
      setState(() {
        iSFileReady = false;
      });
    }
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildUploadForm();
  }

  checkDate() {
    // var now = new DateTime.now();
    // var formatter = new DateFormat('yyyy-MM-dd');
    // String formattedDate = formatter.format(now);
    // print("the normal date is: $formattedDate");
    //
    // DateTime tempDate = DateFormat().parse(formattedDate);
    // print("after formatting: $tempDate");
    // String n = tempDate.toString();
    // if (n != null && n.length >= 5) {
    //   n = n.substring(0, n.length - 12);
    //   print("the formatted date is: $tempDate");
    // }

    // print("This is the current date: $tempDate");
    //

    //  var now = new DateTime.now();
    // //  print("the date is: $now");
    //  var berlinWallFellDate = new DateTime.utc(2021, 09, 20);
    // 0 denotes being equal positive value greater and negative value being less
    // if (selectedDate.compareTo(now) > 0) {
    //   print("is equal");
    // }
  }

  closeKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  handleSubmit() async {
    closeKeyBoard();
    if (titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedDate != null &&
        location != "" &&
        category != "" &&
        report_for_who != "" &&
        explicitLocationController.text.toString().trim().length != 2) {
      setState(() {
        isUploading = true;
        _isLoading = true;
      });
      if (iSFileReady) {
        // File: file is ready
        if (selectedFiles.isNotEmpty) {
          await uploadMultipleImages();
        }
      } else {
        // file is not ready
      }

      if (isSwitched == false) {
        // print("Post anonymously: OFF");
        isAnonymous = widget.currentUser!.username;
      } else {
        // print("Post anonymously: ON");
        isAnonymous = "Anonymous user";
      }

      // print("download uri for each file $downloadedFileUrls");
      await createPostInFirestore(
          contactInfoController.text,
          report_for_who,
          location,
          explicitLocationController.text,
          descriptionController.text,
          titleController.text,
          category,
          downloadedFileUrls,
          selectedDate,
          isAnonymous);
      titleController.clear();
      descriptionController.clear();
      setState(() {
        selectedFiles = [];
        iSFileReady = false;
        isUploading = false;
        _isLoading = false;
        postId = Uuid().v4();
      });
      showSuccessDialog();
    } else {
      showErrorDialog();
    }
  }

  goHome() {
    // Timer(Duration(seconds: 1), () {
    //  print("Yeah, this line is printed after 5 seconds");
    //onPageChanged(1);
    // onTap();
    //  onTap(1);
    //   controller.jumpToPage(1);

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home("timestamp", true)),
        ModalRoute.withName("/Home"));

    // Navigator.pushReplacement(context,
    //     MaterialPageRoute(builder: (context) => Home("timestamp", true)));

    //
    //});
  }
}

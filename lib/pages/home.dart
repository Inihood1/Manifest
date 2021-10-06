import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_test/models/user.dart';
import 'package:social_test/pages/profile.dart';
import 'package:social_test/pages/search.dart';
import 'package:social_test/pages/timeline.dart';
import 'package:social_test/welcome/welcome.dart';
import 'package:stylish_dialog/stylish_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'activity_feed.dart';
import 'login.dart';
import 'new_post.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final userPostsRef = Firestore.instance.collection('userPosts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final postTopicRef = Firestore.instance.collection('topics');
final reports = Firestore.instance.collection('reports');
final DateTime timestamp = DateTime.now();
FirebaseAuth auth = FirebaseAuth.instance;
User? currentUser;

class Home extends StatefulWidget {
  final String orderBy;
  final bool keepAlive;

  Home(this.orderBy, this.keepAlive);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _email = '', _name = '', _password = '';

  TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 10.0);
  TextStyle linkStyle = TextStyle(
      color: Colors.lightBlue, fontSize: 20.0, fontWeight: FontWeight.bold);
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextStyle termsDefaultStyle = TextStyle(color: Colors.white, fontSize: 16.0);
  TextStyle termsLinkStyle = TextStyle(color: Colors.blue);
  var showBadge = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;
  // for facebook
  bool isSignIn = false;
  late StylishDialog dialog;
  FacebookLogin facebookLogin = FacebookLogin();
  bool _isLoading = false;

  Future<void> handleLogin() async {
    final FacebookLoginResult result = await facebookLogin.logIn(['email']);
    switch (result.status) {
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        break;
      case FacebookLoginStatus.loggedIn:
        try {
          await loginWithFacebook(result);
        } catch (e) {
          print(e);
        }
        break;
    }
  }

  Future loginWithFacebook(FacebookLoginResult result) async {
    setState(() {
      _isLoading = true;
    });
    final FacebookAccessToken accessToken = result.accessToken;
    AuthCredential credential =
        FacebookAuthProvider.getCredential(accessToken: accessToken.token);
    var facebookUser = await auth.signInWithCredential(credential);
    if (facebookUser != null) {
      showLoaderDialog();

      await createUserInFirestoreForFb(facebookUser);
      // Navigator.pop(context);
      //  dialog.dismiss();
      setState(() {
        _isLoading = false;
        isAuth = true;
      });
      configurePushNotifications(facebookUser.uid);
    } else {
      setState(() {
        isAuth = false;
        _isLoading = false;
      });
    }
    // print(facebookUser);
  }

  checkFirstTimeIntro() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('first_time1') ?? false);
    if (_seen) {
      return;
    } else {
      await prefs.setBool('first_time1', true);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Welcome()));
    }
  }

  void checkLoginAndType() async {
    setState(() {
      _isLoading = true;
    });
    await checkFirstTimeIntro();
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID') ?? 0;
    if (userID != 0) {
      //  print( "it is not  empty");
      // requestNotification();
      await updateUser(userID.toString());
      // Navigator.pop(context);
      //   dialog.dismiss();
      setState(() {
        _isLoading = false;
        isAuth = true;
      });
      requestNotification();
      getNotificationChanges();
      // configurePushNotifications(userID.toString());
    } else {
      setState(() {
        _isLoading = false;
        isAuth = false;
      });
      // await checkFirstTimeIntro();
      //   checkFirstTimeIntro();
    }
  }

  @override
  initState() {
    super.initState();
    pageController = PageController();

    checkLoginAndType();

    // createNotification();

    requestNotification();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleGoogleSignIn(account);
    }, onError: (err) {
      //   print('Error signing in: $err');
    });
  }

  handleGoogleSignIn(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication googleAuth = await account.authentication;
    // Create a new credential
    setState(() {
      _isLoading = true;
    });
    final credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
    // Once signed in, return the UserCredential
    var googleUser = await auth.signInWithCredential(credential);
    if (googleUser != null) {
      //showLoaderDialog();
      await createUserInFirestoreForGoogle();
      //  Navigator.pop(context);
      //  dialog.dismiss();
      setState(() {
        _isLoading = false;
        isAuth = true;
      });
      configurePushNotifications(account.id);
    } else {
      setState(() {
        _isLoading = false;
        isAuth = false;
      });
    }
  }

  configurePushNotifications(String userID) {
    // final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) {
      getiOSPermission();
    }

    _firebaseMessaging.getToken().then((token) {
      usersRef.document(userID).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
    );

    //  _firebaseMessaging.subscribeToTopic("topic");
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
     // print("Settings registered: $settings");
    });
  }

  updateUser(String userId) async {
    // await usersRef.document(userId).updateData({"account_status": "green"});
    DocumentSnapshot doc = await usersRef.document(userId).get();

    if (!doc.exists) {
      doc = await usersRef.document(userId).get();
    }
    currentUser = User.fromDocument(doc);
    //  await followTopicsAndMe(userId);
    // Navigator.pop(context);
  }

  showLoaderDialog() {
    setState(() {
      _isLoading = true;
    });

    //dismiss stylish dialog
    // dialog.dismiss();
    // ProgressDialog pd = ProgressDialog(context: context);
    // pd.show(msg: 'File Downloading...', max: 100);
  }

  createUserInFirestoreForGoogle() async {
    //  //showLoaderDialog();
    // 1) check if user exists in users collection in database (according to their id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      // final username = await Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // 3) get username from create account, use it to make new user document in users collection
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": user.displayName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "account_status": "green",
        "timestamp": timestamp
      });
      // make new user their own follower (to include their posts in their timeline)
      await followTopicsAndMe(user.id);
      await saveUserInfoForGoogle(user.id);
      doc = await usersRef.document(user.id).get();
    }
    await saveUserInfoForGoogle(user.id);
    currentUser = User.fromDocument(doc);
    // Navigator.pop(context); // close dialog
  }

  createUserInFirestoreForFb(FirebaseUser facebookUser) async {
    DocumentSnapshot doc = await usersRef.document(facebookUser.uid).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      // final username = await Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // 3) get username from create account, use it to make new user document in users collection
      usersRef.document(facebookUser.uid).setData({
        "id": facebookUser.uid,
        "username": facebookUser.displayName,
        "photoUrl": facebookUser.photoUrl,
        "email": facebookUser.email,
        "displayName": facebookUser.displayName,
        "bio": "",
        "account_status": "green",
        "timestamp": timestamp
      });
      // make new user their own follower (to include their posts in their timeline)
      await followTopicsAndMe(facebookUser.uid);
      await saveUserInfoForForfacebook(facebookUser.uid);
      doc = await usersRef.document(facebookUser.uid).get();
    }
    await saveUserInfoForForfacebook(facebookUser.uid);
    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.jumpToPage(
      pageIndex,
    );

    if (pageIndex == 1) {
      setState(() {
        showBadge = false;
      });
    }
  }

  getNotificationChanges() {
    activityFeedRef
        .document(currentUser!.id)
        .collection('feedItems')
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        switch (change.type) {
          case DocumentChangeType.added:
            setState(() {
              showBadge = true;
            });
            // print("added");
            break;
          case DocumentChangeType.modified:
            // print("modified");
            break;
          case DocumentChangeType.removed:
            // print("removed");
            break;
        }
      });
    });
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: [
          Timeline(
              currentUser: currentUser,
              orderBy: widget.orderBy,
              keepAlive: widget.keepAlive),
          ActivityFeed(),
          NewPost(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser!.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          // inactiveColor: Colors.white10,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home)),
            BottomNavigationBarItem(
                icon: Badge(
                    showBadge: showBadge,
                    badgeContent:
                        Text("", style: TextStyle(color: Colors.white)),
                    child: Icon(Icons.notifications))),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add,
              ),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search)),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
          ]),
    );
  }

  Scaffold buildUnAuthScreen(bool _saving) {
    // print("this is the bool value $_saving");
    return Scaffold(
        body: LoadingOverlay(
      isLoading: _saving,
      child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).accentColor,
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                constraints: BoxConstraints(
                  minHeight: 100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo_no_bg.png',
                        fit: BoxFit.scaleDown,
                        width: 250,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (text) {
                                    if (text!.trim().length < 3) {
                                      return "Name must be 3 characters or more!";
                                    }
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _name = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                      errorStyle:
                                          TextStyle(color: Colors.white),
                                      prefixIcon: Icon(Icons.person),
                                      hintText: 'Name',
                                      labelText: "Name",
                                      border: InputBorder.none,
                                      fillColor: Color(0xfff3f3f4),
                                      filled: true)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                  validator: (text) {
                                    if (!text!.contains("@")) {
                                      return "Email not valid!";
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _email = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                      labelText: "Email",
                                      errorStyle:
                                          TextStyle(color: Colors.white),
                                      prefixIcon: Icon(Icons.email),
                                      hintText: 'Email',
                                      border: InputBorder.none,
                                      fillColor: Color(0xfff3f3f4),
                                      filled: true)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                  validator: (text) {
                                    if (text!.length < 8) {
                                      return "Password must be 8 characters or more!";
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _password = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                      labelText: "Password",
                                      errorStyle:
                                          TextStyle(color: Colors.white),
                                      prefixIcon: Icon(Icons.lock),
                                      hintText: 'Password',
                                      border: InputBorder.none,
                                      fillColor: Color(0xfff3f3f4),
                                      filled: true)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: defaultStyle,
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Or sign in ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                              TextSpan(
                                  text: 'Here',
                                  style: linkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      signin();
                                    }),
                            ],
                          ),
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Theme.of(context).accentColor),
                            onPressed: () {
                              register();
                            },
                            child: Text(
                              "Register",
                              style: TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: SignInButton(
                        Buttons.GoogleDark,
                        mini: false,
                        text: "Sign up with Google",
                        onPressed: () {
                          login();
                        },
                      ),
                    ),
                    SignInButton(
                      Buttons.Facebook,
                      mini: false,
                      text: "Sign up with Facebook",
                      onPressed: () {
                        handleLogin();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: termsDefaultStyle,
                              children: [
                                TextSpan(
                                    text: 'By Signing up, you agree to our '),
                                TextSpan(
                                    text: 'Terms of Service',
                                    style: termsLinkStyle,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchTermsURL(
                                            "https://chunskennels.com/manifest-terms-of-service.html");
                                        // print('Terms of Service');
                                      }),
                                TextSpan(text: ' and ', style: TextStyle()),
                                TextSpan(
                                    text: 'Privacy Policy',
                                    style: termsLinkStyle,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchPrivacyURL(
                                            "https://chunskennels.com/manifest-policy.html");
                                        // print('Privacy Policy"');
                                      }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    ));
  }

  launchTermsURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  launchPrivacyURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen(_isLoading);
  }

  saveUserInfoForGoogle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userID', id);
    prefs.setString('type', "g");
  }

  saveUserInfoForForfacebook(String id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userID', id);
    prefs.setString('type', "f");
  }

  saveUserInfoForEmail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userID', id);
    prefs.setString('type', "e");
  }

  closeKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  Future<void> register() async {
    if (_formKey.currentState!.validate()) {
      closeKeyBoard();
      setState(() {
        _isLoading = true;
      });
      await auth
          .createUserWithEmailAndPassword(email: _email, password: _password)
          .then((user) async {
        await createUserInFirestoreForEmail(user);
        await user.sendEmailVerification();
        setState(() {
          _isLoading = false;
        });
        sendEmailDialog();
        configurePushNotifications(user.uid);
      }).catchError((onError) {
        setState(() {
          _isLoading = false;
        });
        if (onError.toString().contains("ERROR_USER_NOT_FOUND")) {
          showErrorDialog("Sorry, the user is not found");
        } else if (onError.toString().contains("ERROR_WRONG_PASSWORD")) {
          showErrorDialog("Wrong password");
        } else if (onError
            .toString()
            .contains("ERROR_NETWORK_REQUEST_FAILED")) {
          showErrorDialog(
              "Something isn't right, please check your connection.");
        } else if (onError.toString().contains("ERROR_INVALID_EMAIL")) {
          showErrorDialog("Invalid email");
        } else {
          showErrorDialog("Unknown error.");
        }
        // print("error sms: $onError");
      });
    }
  }

  showErrorDialog(String error) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Awe snap!'),
            content: Text("$error"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  sendEmailDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Awe snap!'),
            content: Text(
                "A verification link has been sent your mail, please go over and verify"),
            actions: [
              FlatButton(
                color: Colors.blueAccent,
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  void signin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Login(
            // profileId: profileId,
            ),
      ),
    );
  }

  createUserInFirestoreForEmail(FirebaseUser firebase_user) async {
    // 1) check if user exists in users collection in database (according to their id)
    // final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(firebase_user.uid).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      // final username = await Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // 3) get username from create account, use it to make new user document in users collection
      usersRef.document(firebase_user.uid).setData({
        "id": firebase_user.uid,
        "username": _name,
        "photoUrl":
            "https://firebasestorage.googleapis.com/v0/b/socialflutter-9f29a.appspot.com/o/logo.png?alt=media&token=4621d3d4-0c80-4156-bf8e-8a5fb53d1962",
        "email": _email,
        "displayName": _name,
        "bio": "",
        "account_status": "green",
        "timestamp": timestamp
      });
      // make new user their own follower (to include their posts in their timeline)
      await followTopicsAndMe(firebase_user.uid);
      //  await saveUserInfoForEmail(firebase_user.uid);
      doc = await usersRef.document(firebase_user.uid).get();
    }
    //await saveUserInfoForEmail(firebase_user.uid);
    currentUser = User.fromDocument(doc);
  }

  Future<void> followTopicsAndMe(String id) async {
    await followersRef
        .document(id)
        .collection('userFollowers')
        .document(id)
        .setData({});
/////////////////////////////////////

    await followersRef
        .document("Ableism")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Ableism")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Assault or harassment")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Assault or harassment")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Bribes")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Bribes")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Tribalism")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Tribalism")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Unsanitary conditions")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Unsanitary conditions")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Non payment of salary")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Non payment of salary")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Child abuse")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Child abuse")
        .setData({});

//////////////////////////////////

    await followersRef
        .document("Stalking")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Stalking")
        .setData({});
    //////////////////////////////////

    await followersRef
        .document("Others")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Others")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Violence")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Violence")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Gender-based violence")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Gender-based violence")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Sexual harassment")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Sexual harassment")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Drug abuse")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Drug abuse")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Poor public service")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Poor public service")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Government corruption")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Government corruption")
        .setData({});
    //////////////////////////////////

    //////////////////////////////////

    await followersRef
        .document("Other corrupt practices")
        .collection('userFollowers')
        .document(id)
        .setData({});

    await followingRef
        .document(id)
        .collection('userFollowing')
        .document("Other corrupt practices")
        .setData({});
    //////////////////////////////////
  }

  requestNotification() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  createNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Manifest',
            body: "lorem ipsum dolo sit amet"));
  }
}

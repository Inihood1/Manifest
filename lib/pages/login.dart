import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_test/models/user.dart';
import 'package:social_test/pages/home.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _email = '', _password = '';
  bool _isLoading = false;
  TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 10.0);
  TextStyle linkStyle = TextStyle(
      color: Colors.lightBlue, fontSize: 20.0, fontWeight: FontWeight.bold);
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FirebaseAuth auth = FirebaseAuth.instance;

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
                                      errorStyle:
                                          TextStyle(color: Colors.white),
                                      prefixIcon: Icon(Icons.lock),
                                      hintText: 'Password',
                                      border: InputBorder.none,
                                      fillColor: Color(0xfff3f3f4),
                                      filled: true)),
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Theme.of(context).accentColor),
                                onPressed: () {
                                  login();
                                },
                                child: Text(
                                  "       Login     ",
                                  style: TextStyle(color: Colors.white),
                                )),
                            RichText(
                              text: TextSpan(
                                style: defaultStyle,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Create a new account ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  TextSpan(
                                      text: 'Here',
                                      style: linkStyle,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          register();
                                        }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return buildUnAuthScreen(_isLoading);
  }

  closeKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  void login() async {
    if (_formKey.currentState!.validate()) {
      closeKeyBoard();
      setState(() {
        _isLoading = true;
      });
      await auth
          .signInWithEmailAndPassword(email: _email, password: _password)
          .then((user) async {
        if (user.isEmailVerified) {
          await getUserInfoIntoApp(user);
          setState(() {
            _isLoading = false;
          });
          successLogin();
          // print("the email is verified: $user");
        } else {
          setState(() {
            _isLoading = false;
          });
          showErrorDialog("This email is not verified");
          // print("the email not is verified: $user")
        }
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

  void register() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home("likes", true)),
        ModalRoute.withName("/Home"));

    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Home(
    //         // profileId: profileId,
    //         ),
    //   ),
    // );
  }

  void successLogin() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home("likes", true)),
        ModalRoute.withName("/Home"));
  }

  getUserInfoIntoApp(FirebaseUser firebase_user) async {
    // 1) check if user exists in users collection in database (according to their id)
    // final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(firebase_user.uid).get();
    await saveUserInfoForForEmail(firebase_user.uid);
    currentUser = User.fromDocument(doc);
  }

  saveUserInfoForForEmail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userID', id);
    prefs.setString('type', "e");
  }
}

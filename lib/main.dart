// @dart=2.9
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:social_test/pages/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications()
      .initialize(null, [NotificationChannel(channelKey: 'basic_channel')]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manifest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepPurple,
      ),
      home: Home("likes", false),
    );
  }
}

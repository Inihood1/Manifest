import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String account_status;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.displayName,
    required this.bio,
    required this.account_status,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      account_status: doc['account_status'],
    );
  }
}

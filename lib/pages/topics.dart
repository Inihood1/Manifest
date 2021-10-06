import 'package:cloud_firestore/cloud_firestore.dart';

class Topics{
  final String icon;
  final String name;

  Topics({
    required this.icon,
    required this.name,
  });

  factory Topics.fromDocument(DocumentSnapshot doc) {
    return Topics(
      icon: doc['icon'],
      name: doc['name']
    );
  }
}
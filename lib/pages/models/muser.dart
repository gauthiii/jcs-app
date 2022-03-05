import 'package:cloud_firestore/cloud_firestore.dart';

class Muser {
  final String id;
  final String email;
  final String photoUrl;
  final String displayName;
  final String stat;
  final String pwd;
  final List<dynamic> ids;
  final Timestamp timestamp;

  Muser(
      {this.id,
      this.email,
      this.photoUrl,
      this.displayName,
      this.stat,
      this.pwd,
      this.ids,
      this.timestamp});

  factory Muser.fromDocument(DocumentSnapshot doc) {
    return Muser(
        id: doc['id'],
        email: doc['email'],
        photoUrl: doc['photoUrl'],
        displayName: doc['displayName'],
        stat: doc['stat'],
        pwd: doc['pwd'],
        ids: doc['Ids'],
        timestamp: doc['timestamp']);
  }
}

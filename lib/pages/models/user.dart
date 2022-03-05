import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String access;
  final String Fp;
  final String face_file;
  final Timestamp timestamp;
  final bool isLock;

  User(
      {this.id,
      this.username,
      this.email,
      this.photoUrl,
      this.displayName,
      this.bio,
      this.access,
      this.Fp,
      this.face_file,
      this.timestamp,
      this.isLock});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
        id: doc['id'],
        email: doc['email'],
        username: doc['username'],
        photoUrl: doc['photoUrl'],
        displayName: doc['displayName'],
        bio: doc['bio'],
        Fp: doc['Fp'],
        face_file: doc['face_file'],
        access: doc['access'],
        timestamp: doc['timestamp'],
        isLock: doc['isLock']);
  }
}

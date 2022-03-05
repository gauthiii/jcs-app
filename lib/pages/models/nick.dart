import 'package:cloud_firestore/cloud_firestore.dart';

class Nick {
  final dynamic nicknames;

  Nick({this.nicknames});

  factory Nick.fromDocument(DocumentSnapshot doc) {
    return Nick(
      nicknames: doc['nicknames'],
    );
  }
}

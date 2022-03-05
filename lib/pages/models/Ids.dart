import 'package:cloud_firestore/cloud_firestore.dart';

class Id {
  final String id;

  Id({
    this.id,
  });

  factory Id.fromDocument(DocumentSnapshot doc) {
    return Id(id: doc['id']);
  }
}

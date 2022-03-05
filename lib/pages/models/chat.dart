import 'package:cloud_firestore/cloud_firestore.dart';

class Chats {
  final String mid;
  final String message;
  final String senderId;
  final String senderName;
  final String senderPhoto;
  final String recieverId;
  final String recieverName;
  final String recieverPhoto;
  final Timestamp timestamp;
  final bool isSeen;
  final bool isRecieve;

  Chats(
      {this.mid,
      this.message,
      this.senderId,
      this.senderName,
      this.senderPhoto,
      this.recieverId,
      this.recieverName,
      this.recieverPhoto,
      this.timestamp,
      this.isSeen,
      this.isRecieve});

  factory Chats.fromDocument(DocumentSnapshot doc) {
    return Chats(
        mid: doc['mid'],
        message: doc['message'],
        senderId: doc['senderId'],
        senderName: doc['senderName'],
        senderPhoto: doc['senderPhoto'],
        recieverId: doc['recieverId'],
        recieverPhoto: doc['recieverPhoto'],
        recieverName: doc['recieverName'],
        timestamp: doc['timestamp'],
        isSeen: doc['isSeen'],
        isRecieve: doc['isRecieve']);
  }
}

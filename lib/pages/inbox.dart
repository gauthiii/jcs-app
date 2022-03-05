import 'package:Joint/pages/chat_box.dart';
import 'package:Joint/pages/models/muser.dart';
import 'package:Joint/pages/profile.dart';
import 'package:Joint/pages/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'models/chat.dart';

class Inbox extends StatefulWidget {
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  bool isLoading = false;

  Muser x;

  @override
  void initState() {
    super.initState();

    gettexts();
  }

  List<Chats> ch = [];
  List<String> id = [];

  gettexts() async {
    if (this.mounted) {
      setState(() {
        isLoading = true;
        ch = [];
        id = [];
      });
    }

    QuerySnapshot snapshot3 = await mref
        .document(currentMuser.id)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    if (snapshot3.documents.length == 0) {
      if (this.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }

    if (currentMuser.ids.length == 0) {
      if (this.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }

    snapshot3.documents.forEach((d) {
      Chats x = Chats.fromDocument(d);

      if (x.recieverId != currentMuser.id) {
        if (!id.contains(x.recieverId)) {
          id.add(x.recieverId);
          ch.add(x);
        }
      } else {
        if (!id.contains(x.senderId)) {
          id.add(x.senderId);
          ch.add(x);
        }
      }
    });

    DocumentSnapshot doc = await musersRef.document(currentMuser.id).get();

    if (this.mounted) {
      setState(() {
        x = Muser.fromDocument(doc);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text("Inbox"),
          ),
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 300,
                color: Colors.black,
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "YOUR INBOX IS LOADING....",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Bangers",
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              circularProgress()
            ],
          )));
    } else if (ch.length == 0)
      return Scaffold(
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text("Inbox"),
          ),
          body: RefreshIndicator(
            child:ListView(children: [
              Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 300,
                  color: Colors.black,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "NO CONVERSATIONS!!!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 50.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ))
            ],) ,
            onRefresh: () async {
              gettexts();
            },
          ));
    else if (ch.length > 0)
      return RefreshIndicator(
          child: Scaffold(
              backgroundColor: Colors.orange[200],
              appBar: AppBar(
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: Text("Inbox"),
              ),
              body: ListView.separated(
                itemCount: ch.length,
                separatorBuilder: (BuildContext context, int index) => Divider(
                  color: Colors.black,
                  thickness: 0,
                  height: 0,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            showChat(context,
                                uid: currentMuser.id,
                                profileId:
                                    (currentMuser.id == ch[index].recieverId)
                                        ? ch[index].senderId
                                        : ch[index].recieverId);
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25.0,
                              backgroundColor: Colors.grey,
                              backgroundImage: (currentMuser.photoUrl ==
                                      ch[index].senderPhoto)
                                  ? CachedNetworkImageProvider(
                                      ch[index].recieverPhoto)
                                  : CachedNetworkImageProvider(
                                      ch[index].senderPhoto),
                            ),
                            title: (currentMuser.displayName ==
                                    ch[index].recieverName)
                                ? Text(
                                    ch[index].senderName,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17),
                                  )
                                : Text(
                                    ch[index].recieverName,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17),
                                  ),
                            subtitle: (currentMuser.displayName ==
                                    ch[index].senderName)
                                ? ((ch[index].isRecieve == false)
                                    ? Text(
                                        "Your Message has been Sent",
                                        style: TextStyle(color: Colors.black45),
                                      )
                                    : Text(
                                        "Your Message has been Opened",
                                        style: TextStyle(color: Colors.black45),
                                      ))
                                : ((ch[index].isSeen == false &&
                                        currentMuser.id == ch[index].recieverId)
                                    ? Text(
                                        "New Message",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        "You've Opened their message",
                                        style: TextStyle(
                                          color: Colors.black45,
                                        ),
                                      )),
                            trailing: (ch[index].isSeen == false &&
                                    currentMuser.id == ch[index].recieverId)
                                ? Text(
                                    "${funny(ch[index].timestamp.toDate().toString())}\n${funny1(ch[index].timestamp.toDate().toString())}",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    "${funny(ch[index].timestamp.toDate().toString())}\n${funny1(ch[index].timestamp.toDate().toString())}",
                                    style: TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                          ),
                        ),
                        (index == ch.length - 1)
                            ? Divider(
                                color: Colors.black,
                              )
                            : Container(width: 0, height: 0)
                      ],
                    ),
                  );
                },
              )),
          // ignore: missing_return
          onRefresh: () {
            gettexts();
          });
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}

showChat(BuildContext context, {String profileId, String uid}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Chat(chatId: profileId, proid: uid),
    ),
  );
}

String funny1(String x) {
  String a, b, c, d;
  int q;

  a = x.substring(11, 16);
  int p = int.parse(a.substring(0, 2));
  if (p == 0) {
    p += 12;
    a = String.fromCharCode(p) + x.substring(13, 16) + " AM";
  } else if (p >= 1 && p <= 11) {
    a = a + " AM";
  } else if (p == 12) {
    a = a + " PM";
  } else if (p > 12) {
    p -= 12;
    a = String.fromCharCode(p) + x.substring(13, 16) + " PM";
  }

  b = x.substring(2, 4);
  q = int.parse(x.substring(5, 7));

  switch (q) {
    case 1:
      c = "Jan";
      break;
    case 2:
      c = "Feb";
      break;
    case 3:
      c = "Mar";
      break;
    case 4:
      c = "Apr";
      break;
    case 5:
      c = "May";
      break;
    case 6:
      c = "Jun";
      break;
    case 7:
      c = "Jul";
      break;
    case 8:
      c = "Aug";
      break;
    case 9:
      c = "Sep";
      break;
    case 10:
      c = "Oct";
      break;
    case 11:
      c = "Nov";
      break;
    case 12:
      c = "Dec";
      break;
    default:
      break;
  }

  b = x.substring(8, 10) + "-" + c + "-" + b;

  return b;
}

String funny(String x) {
  String a;

  a = x.substring(11, 16);

  int p = int.parse(a.substring(0, 2));

  if (p == 0) {
    p += 12;

    a = p.toString() + x.substring(13, 16) + " AM";
  } else if (p >= 1 && p <= 11) {
    a = a + " AM";
  } else if (p == 12) {
    a = a + " PM";
  } else if (p > 12) {
    p -= 12;

    a = p.toString() + x.substring(13, 16) + " PM";
  }

  return a;
}

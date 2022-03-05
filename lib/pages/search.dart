import 'package:Joint/pages/chat_box.dart';
import 'package:Joint/pages/models/fid.dart';
import 'package:Joint/pages/widgets/custom_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/profile.dart';
import './models/user.dart';
import './home.dart';
import './widgets/progress.dart';
import 'models/nick.dart';

String un = "un";
Nick nicknames;

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  FocusNode _focus = new FocusNode();
  bool g = false;
  bool s = false;

  List<GridTile> gridTiles = [];
  List<UserResult> searchResults = [];

  @override
  void initState() {
    super.initState();

    _focus.addListener(_onFocusChange);

    getU();
  }

  getU() async {
    setState(() {
      g = true;
    });
    var users = await usersRef.getDocuments();

    var ids = await timeRef.document(currentUser.id).get();

    Fid fid = Fid.fromDocument(ids);

    users.documents.forEach((d) {
      User u = User.fromDocument(d);

      setState(() {
        if (fid.fid.contains(u.id))
          gridTiles.add(GridTile(
            child: FlatButton(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 4)),
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(u.photoUrl),
                    radius: 25,
                    backgroundColor: Colors.grey,
                  ),
                  Padding(padding: EdgeInsets.only(bottom: 4)),
                ],
              ),
              onPressed: () => showProfile(context, profileId: u.id),
            ),
          ));
      });
    });

    setState(() {
      g = false;
    });
  }

  void _onFocusChange() {
    debugPrint("Focus: " + _focus.hasFocus.toString());
  }

  handleSearch(query) async {
    setState(() {
      searchResults = [];
      s = true;
    });

    QuerySnapshot users = await usersRef.getDocuments();

    DocumentSnapshot n = await nickRef.document(currentUser.id).get();

    setState(() {
      searchResults = [];
      if (query.length > 0)
        users.documents.forEach((doc) {
          User user = User.fromDocument(doc);

          UserResult searchResult = UserResult(user);

          if (un == "nick") {
            if (n.exists) {
              nicknames = Nick.fromDocument(n);

              if (nicknames.nicknames.length > 0 &&
                  nicknames.nicknames[user.id] != null) {
                if (query == ":all:")
                  searchResults.add(searchResult);
                else {
                  var x = ((query.length > nicknames.nicknames[user.id].length)
                      ? nicknames.nicknames[user.id].toUpperCase()
                      : nicknames.nicknames[user.id]
                          .toUpperCase()
                          .substring(0, query.length));

                  if (x == query.toUpperCase()) searchResults.add(searchResult);
                }
              }
            }
          } else {
            if (query == ":all:")
              searchResults.add(searchResult);
            else {
              var x = (un == "un")
                  ? ((query.length > user.username.length)
                      ? user.username.toUpperCase()
                      : user.username.toUpperCase().substring(0, query.length))
                  : ((query.length > user.displayName.length)
                      ? user.displayName.toUpperCase()
                      : user.displayName
                          .toUpperCase()
                          .substring(0, query.length));

              if (x == query.toUpperCase()) searchResults.add(searchResult);
            }
          }
        });

      s = false;
    });
  }

  clearSearch() {
    setState(() {
      searchResults = [];
      if (_focus.hasFocus == true) _focus.unfocus();
      searchController.clear();
    });
  }

  AppBar buildSearchField() {
    return AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: TextFormField(
          focusNode: _focus,
          autofocus: false,
          style: TextStyle(
              fontSize: 18.0,
              color: Colors.orange[200],
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins-Regular"),
          controller: searchController,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              borderSide: BorderSide(color: Colors.white38, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              borderSide: BorderSide(color: Colors.white38),
            ),
            contentPadding: EdgeInsets.all(8),
            hintText: "Search User ...",
            hintStyle: TextStyle(
                fontSize: 12.0,
                color: Colors.white38,
                fontFamily: "Poppins-Regular"),
            prefixIcon: Icon(Icons.people, color: Colors.white38),
            suffixIcon: (_focus.hasFocus || searchResults.length > 0)
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white38),
                    onPressed: clearSearch,
                  )
                : IconButton(
                    icon: Icon(Icons.search, color: Colors.white38),
                    onPressed: () {},
                  ),
          ),
          onChanged: (val) {
            handleSearch(val.trim());
          },
          onFieldSubmitted: (val) {
            print("val : " + val.trim());
            handleSearch(val.trim());
          },
        ));
  }

  button() {
    return Container(
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RaisedButton(
                color: (un == "un") ? Colors.orange[200] : Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(
                        color:
                            (un == "un") ? Colors.black : Colors.orange[200])),
                onPressed: () {
                  setState(() {
                    un = "un";
                  });
                },
                child: Text("Username",
                    style: TextStyle(
                        color:
                            (un == "un") ? Colors.grey[900] : Colors.white))),
            RaisedButton(
                color: (un == "nm") ? Colors.orange[200] : Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(
                        color:
                            (un == "nm") ? Colors.black : Colors.orange[200])),
                onPressed: () {
                  setState(() {
                    un = "nm";
                  });
                },
                child: Text("Name",
                    style: TextStyle(
                        color:
                            (un == "nm") ? Colors.grey[900] : Colors.white))),
            RaisedButton(
                color: (un == "nick") ? Colors.orange[200] : Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(
                        color: (un == "nick")
                            ? Colors.black
                            : Colors.orange[200])),
                onPressed: () {
                  setState(() {
                    un = "nick";
                  });
                },
                child: Text("Nickname",
                    style: TextStyle(
                        color:
                            (un == "nick") ? Colors.grey[900] : Colors.white)))
          ],
        ));
  }

  buildNoContent() {
    return ListView(
      children: <Widget>[
        button(),
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 250,
                color: Colors.black,
              ),
              Text(
                "Find Users!!!!!!!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "Bangers",
                  fontSize: 50.0,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  buildSearchResults() {
    return Container(
        height: MediaQuery.of(context).size.height,
        child: (s == true)
            ? Column(children: [
                Padding(
                  padding: EdgeInsets.only(top: 10),
                ),
                circularProgress()
              ])
            : ((searchResults.length > 0)
                ? ListView(
                    children: searchResults,
                  )
                : Center(
                    child: Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text(
                      "Not found",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "FredokaOne",
                        fontSize: 50.0,
                      ),
                    ),
                  ))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[200],
      appBar: buildSearchField(),
      body: (g == true)
          ? circularProgress()
          : (searchController.text.length == 0
              ? buildNoContent()
              : buildSearchResults()),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 8)),
        Container(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
                onTap: () => showProfile(context, profileId: user.id),
                leading: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Colors.grey,
                  backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                ),
                title: Text(
                  (un == "un")
                      ? user.username
                      : ((un == "nm")
                          ? user.displayName
                          : nicknames.nicknames[user.id]),
                  style: TextStyle(
                      color: Colors.orange[200], fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  (un == "un")
                      ? user.displayName
                      : ((un == "nm") ? user.username : user.displayName),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: (user.id != currentUser.id)
                    ? IconButton(
                        splashColor: Colors.grey[900],
                        icon: Icon(Icons.mail, color: Colors.orange[200]),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Chat(chatId: user.id, proid: currentUser.id),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 0,
                        height: 0,
                      )),
          ),
        ),
      ],
    );
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

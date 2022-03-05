import 'package:Joint/FACE/pages/db/database.dart';
import 'package:Joint/FACE/pages/profile.dart';
import 'package:Joint/FACE/services/facenet.service.dart';
import 'package:Joint/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/FACE/pages/home.dart';
import 'package:Joint/pages/models/user.dart';
import 'package:http/http.dart' as http;

class Userx {
  String user;
  String password;

  Userx({@required this.user, @required this.password});

  static Userx fromDB(String dbuser) {
    return new Userx(
        user: dbuser.split(':')[0], password: dbuser.split(':')[1]);
  }
}

class AuthActionButton extends StatefulWidget {
  AuthActionButton(this._initializeControllerFuture,
      {@required this.onPressed, @required this.isLogin});
  final Future _initializeControllerFuture;
  final Function onPressed;
  final bool isLogin;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  /// service injection
  final FaceNetService _faceNetService = FaceNetService();
  final DataBaseService _dataBaseService = DataBaseService();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: currentUser.displayName);
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  Userx predictedUser;

  Future _signUp(context) async {
    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;

    usersRef
        .document(currentUser.id)
        .updateData({"Fp": password, "access": "no"});

    /// creates a new user in the 'database'
    await _dataBaseService.saveData(user, password, predictedData);

    /// resets the face stored in the face net sevice
    this._faceNetService.setPredictedData(null);
    Navigator.pop(context);
    Navigator.pop(context);

    DocumentSnapshot doc = await usersRef.document(guser.id).get();
    currentUser = User.fromDocument(doc);
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    print(password);
    print(this.predictedUser.password);

    if (currentUser.Fp == password) {
      print(" Right PASSWORD!");
      usersRef.document(currentUser.id).updateData({"access": "yes"});
      Navigator.pop(context);
      Navigator.pop(context);

      DocumentSnapshot doc = await usersRef.document(guser.id).get();
      currentUser = User.fromDocument(doc);

      print("sending email");
      var res = await http.get(
          'https://us-central1-joint-club.cloudfunctions.net/sendMail?dest=${currentUser.email}');
      print(res.body);
      print("sent");
    } else {
      print(" WRONG PASSWORD!");
      usersRef.document(currentUser.id).updateData({"access": "incorrect"});
      Navigator.pop(context);
      Navigator.pop(context);

      DocumentSnapshot doc = await usersRef.document(guser.id).get();
      currentUser = User.fromDocument(doc);

      showDialog(
          context: context,
          builder: (_) => new AlertDialog(
                backgroundColor: Colors.white,
                title: new Text("Wrong Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                content: Text("Long Press to Sign in Again",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
              ));
    }
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    return userAndPass ?? null;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: widget.isLogin ? Text('Sign in') : Text('Sign up'),
      icon: Icon(Icons.camera_alt),
      // Provide an onPressed callback.
      onPressed: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;
          // onShot event (takes the image and predict output)
          bool faceDetected = await widget.onPressed();

          if (faceDetected) {
            if (widget.isLogin) {
              var userAndPass = _predictUser();
              if (userAndPass != null) {
                this.predictedUser = Userx.fromDB(userAndPass);
              }
            }
            Scaffold.of(context)
                .showBottomSheet((context) => signSheet(context));
          }
        } catch (e) {
          // If an error occurs, log the error to the console.
          print(e);
        }
      },
    );
  }

  signSheet(context) {
    return Container(
      padding: EdgeInsets.all(20),
      height: 300,
      child: Column(
        children: [
          widget.isLogin && predictedUser != null
              ? Container(
                  child: Text(
                    'Welcome back, ' + predictedUser.user + '! 😄',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : widget.isLogin
                  ? Container(
                      child: Text(
                      'User not found 😞',
                      style: TextStyle(fontSize: 20),
                    ))
                  : Container(),
          !widget.isLogin
              ? TextField(
                  controller: _userTextEditingController,
                  decoration: InputDecoration(labelText: "Your Name"),
                )
              : Container(),
          widget.isLogin && predictedUser == null
              ? Container()
              : TextField(
                  controller: _passwordTextEditingController,
                  decoration:
                      InputDecoration(labelText: "Face-ID-Secret-Password"),
                  obscureText: true,
                ),
          widget.isLogin && predictedUser != null
              ? RaisedButton(
                  child: Text('Provide Access'),
                  onPressed: () async {
                    _signIn(context);
                  },
                )
              : !widget.isLogin
                  ? RaisedButton(
                      child: Text('Save Face-ID'),
                      onPressed: () async {
                        await _signUp(context);
                      },
                    )
                  : Container(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

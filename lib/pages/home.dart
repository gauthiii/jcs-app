import 'dart:io';

import 'package:Joint/FACE/pages/db/database.dart';
import 'package:Joint/FACE/pages/sign-in.dart';
import 'package:Joint/FACE/pages/sign-up.dart';
import 'package:Joint/FACE/pages/widgets/FacePainter.dart';
import 'package:Joint/FACE/pages/widgets/auth-action-button.dart';
import 'package:Joint/FACE/services/camera.service.dart';
import 'package:Joint/FACE/services/facenet.service.dart';
import 'package:Joint/FACE/services/ml_vision_service.dart';
import 'package:Joint/pages/models/muser.dart';
import 'package:Joint/pages/xyz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/Logged.dart';
import 'package:Joint/pages/widgets/progress.dart';
import 'package:Joint/pages/widgets/time_screen.dart';
import 'package:path_provider/path_provider.dart';
import './activity_feed.dart';
import './profile.dart';
import './search.dart';
import './timeline.dart';
import './models/user.dart';
import './create_account.dart';
import './upload.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Joint/FACE/pages/home.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show join;
import 'dart:math' as math;

import 'dm.dart';
import 'inbox.dart';
import 'models/fid.dart';

final usersRef = Firestore.instance.collection('users');
final tokenRef = Firestore.instance.collection('tokens');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followingRef = Firestore.instance.collection('userFollowing');
final followersRef = Firestore.instance.collection('userFollowers');
final timeRef = Firestore.instance.collection('timeline');
final idRef = Firestore.instance.collection('Fid');
final reqRef = Firestore.instance.collection('Req');
final nickRef = Firestore.instance.collection('Nicknames');
//final tpRef = Firestore.instance.collection('tposts');
final musersRef = Firestore.instance.collection('Musers');
final chatRef = Firestore.instance.collection('Chatbox');
final cidRef = Firestore.instance.collection('Convos');
final mref = Firestore.instance.collection('Messages');
final DateTime timestamp = DateTime.now();
bool isFace = false;
bool lock = true;
String text = "";
User currentUser;
Muser currentMuser;

bool isAuth = false;

final GoogleSignIn googleSignIn = GoogleSignIn();
GoogleSignInAccount guser;
final StorageReference storageRef = FirebaseStorage.instance.ref();

PageController pageController;
int pageIndex = 0;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String name, email, pid;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool hisLoading = false;

  List<String> list;

  CameraDescription cameraDescription;
  FaceNetService _faceNetService = FaceNetService();
  MLVisionService _mlVisionService = MLVisionService();
  DataBaseService _dataBaseService = DataBaseService();
  dynamic data = {};

  @override
  void initState() {
    super.initState();

    // Detects when user signed in

    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      if (this.mounted) {
        setState(() {
          hisLoading = true;
        });
      }
      usersRef.document(account.id).updateData({"access": "no"});
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  _startUp() async {
    data = _dataBaseService.db;

    List<CameraDescription> cameras = await availableCameras();

    /// takes the front camera
    cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );

    // start the services
    await _faceNetService.loadModel();
    await _dataBaseService.loadDB();
    _mlVisionService.initialize();
  }

  handleSignIn(GoogleSignInAccount account) async {
    pageIndex = 0;
    pageController = PageController();
    onPageChanged(0);

    if (account != null) {
      print('User signed in!: $account');
      await createUserInFirestore();

      if (this.mounted) {
        setState(() {
          isAuth = true;
          //change
          name = account.displayName;
          email = account.email;
          pid = account.photoUrl;
        });
      }

      setState(() {
        hisLoading = false;
      });

      if (currentUser.face_file == "" && currentUser.isLock == true)
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.black54,

                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.orange[200]),
                    borderRadius: BorderRadius.circular(20)),
                title: new Text("Face Access Setup!!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[200])),
                content: Text("Set up your Face ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[200])),
                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
              );
            });
      else if (currentUser.face_file != "" &&
          currentUser.access == "no" &&
          currentUser.isLock == true)
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.black54,

                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.orange[200]),
                    borderRadius: BorderRadius.circular(20)),
                title: new Text("Face Access Required!!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[200])),
                content: Text("Sign in to get access",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[200])),
                // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
              );
            });

      configurePushNotifications();
    } else {
      if (this.mounted) {
        setState(() {
          isAuth = false;
        });
      }
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});

      tokenRef.document(user.id).setData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        print(recipientId);
        print(user.id);
        if (recipientId == user.id) {
          print("Notification shown!");
        }
        print("Notification NOT shown");
      },
    );
  }

  fun(BuildContext parentContext, String body) {
    showDialog(
        context: parentContext,
        builder: (_) => new AlertDialog(
              title: new Text(body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "JustAnotherHand",
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
            ));
  }

  createUserInFirestore() async {
    _userTextEditingController.text = "";
    _passwordTextEditingController.text = "";
    predictedUser = null;
    // 1) check if user exists in users collection in database (according to their id)
    guser = googleSignIn.currentUser;

    DocumentSnapshot doc = await usersRef.document(guser.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      String mobile = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // 3) get username from create account, use it to make new user document in users collection
      usersRef.document(guser.id).setData({
        "id": guser.id,
        "isFace": false,
        "isLock": true,
        "username": mobile,
        "photoUrl": guser.photoUrl,
        "email": guser.email,
        "displayName": guser.displayName,
        "face_file": "",
        "bio": "",
        "access": "no",
        "timestamp": timestamp
      });

      doc = await usersRef.document(guser.id).get();

      timeRef.document(guser.id).setData({
        "Ids": [],
      });

      reqRef.document(guser.id).setData({
        "follow": [],
        "share_p": [],
        "transfer_p": [],
      });
    }

    currentUser = User.fromDocument(doc);

    print(currentUser);
    print(currentUser.username);

    if (currentUser.isLock == true) {
      await _startUp();
      _start();
      setState(() {
        isFace = false;
      });
    } else
      setState(() {
        isFace = true;
      });

    DocumentSnapshot doc1 = await musersRef.document(guser.id).get();

    if (!doc1.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page

      // 3) get username from create account, use it to make new user document in users collection
      musersRef.document(guser.id).setData({
        "id": guser.id,
        "photoUrl": guser.photoUrl,
        "email": guser.email,
        "displayName": guser.displayName,
        "stat": "(No Status)",
        "pwd": "",
        "timestamp": timestamp,
        "Ids": [],
      });

      doc1 = await musersRef.document(guser.id).get();
    }

    currentMuser = Muser.fromDocument(doc1);
  }

  @override
  void dispose() {
    pageController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  login() {
    if (this.mounted) {
      setState(() {
        hisLoading = true;
      });
    }
    googleSignIn.signIn();

    googleSignIn.onCurrentUserChanged.listen((account) {
      usersRef.document(account.id).updateData({"access": "no"});
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int x) {
    setState(() {
      pageIndex = x;
    });

    switch (x) {
      case 0:
        print("Logged");
        break;
      case 1:
        print("Timeline");
        break;
      case 2:
        print("Notifs");
        break;
      case 3:
        print("Upload");
        break;
      case 4:
        print("Profile");
        break;
      case 5:
        print("Inbox");
        break;
      default:
        print("Null");
        break;
    }
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 200), curve: Curves.bounceOut);
  }

  sendmail() async {
    print("sending email");
    var res = await http.get(
        'https://us-central1-joint-club.cloudfunctions.net/sendMail?dest=${currentUser.email}');
    print(res.body);
    print("sent");
  }

  Widget buildAuthScreen() {
    return WillPopScope(
        // ignore: missing_return
        onWillPop: () {
          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                      backgroundColor: Colors.white,
                      title: new Text("Are you sure??",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      content: new Text("Click yes to exit App",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 15.0, color: Colors.black)),
                      actions: [
                        FlatButton(
                            onPressed: () {
                              exit(0);
                            },
                            child: Text("Yes",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue))),
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("No",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue))),
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Cancel",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)))
                      ]));
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.orange[200],
          // appBar: bar(),
          body: GestureDetector(
            // Using the DragEndDetails allows us to only fire once per swipe.
            onHorizontalDragEnd: (dragEndDetails) {
              if (dragEndDetails.primaryVelocity < 0) {
                // Page forwards
                print('Move page forwards');
                onTap(pageIndex + 1);
              } else if (dragEndDetails.primaryVelocity > 0) {
                // Page backwards
                print('Move page backwards');
                onTap(pageIndex - 1);
              }
            },
            child: PageView(
              children: <Widget>[
                Logged(),
                //Timeline(profileId: currentUser?.id),
                TimeScreen(),
                ActivityFeed(),
                Upload(),
                Search(),
                Inbox(),
                Profile(profileId: currentUser?.id),
             
              ],
              controller: pageController,
              onPageChanged: onPageChanged,
              physics: NeverScrollableScrollPhysics(),
            ),
          ),
          bottomNavigationBar: CupertinoTabBar(
              backgroundColor: Color(0xFF1B1B1B),
              currentIndex: pageIndex,
              onTap: onTap,
              activeColor: Colors.orange[200],
              inactiveColor: Color(0xFF888888),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.photo_camera),
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.search,
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mail),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                ),
               
              ]),
        ));
  }

  face() {
    return Scaffold(
        backgroundColor: Colors.orange[200],
        body: GestureDetector(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.tag_faces,
                  size: 300,
                  color: Colors.black,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "AUTHENTICATION FAILED!!!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 50.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "Tap Once to Sign in Again",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "Double Tap to Sign Out",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Bangers",
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )),
            onTap: () async {
              usersRef.document(currentUser.id).updateData({"access": "no"});
              DocumentSnapshot doc =
                  await usersRef.document(currentUser.id).get();
              _start();
              setState(() {
                currentUser = User.fromDocument(doc);
                isAuth = true;
                isFace = false;

                _detectingFaces = false;
                pictureTaked = false;
                _bottomSheetVisible = false;
              });
            },
            onDoubleTap: () {
              googleSignIn.signOut();
              if (this.mounted) {
                setState(() {
                  isAuth = false;
                  hisLoading = false;
                  isFace = false;

                  _detectingFaces = false;
                  pictureTaked = false;
                  _bottomSheetVisible = false;
                  predictedUser = null;
                });
              }
            },
            onLongPress: () async {
              _dataBaseService.cleanDB();
              usersRef
                  .document(currentUser.id)
                  .updateData({"face_file": "", "Fp": "", "access": "no"});

              storageRef
                  .child("FaceID")
                  .child("/${currentUser.email}")
                  .child("${currentUser.displayName}.json")
                  .delete();

              DocumentSnapshot doc =
                  await usersRef.document(currentUser.id).get();

              setState(() {
                currentUser = User.fromDocument(doc);
                isAuth = true;
                isFace = false;

                _detectingFaces = false;
                pictureTaked = false;
                _bottomSheetVisible = false;
              });
              _start();

              showDialog(
                  context: context,
                  builder: (context) {
                    Future.delayed(Duration(seconds: 1), () {
                      Navigator.of(context).pop(true);
                    });
                    return AlertDialog(
                      backgroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.orange[200]),
                          borderRadius: BorderRadius.circular(20)),
                      title: new Text("Database Cleared",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[200])),
                      content: Text("Set up Face ID again",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[200])),
                      // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
                    );
                  });
            }));
  }

  bar() {
    if (pageIndex == 0)
      return AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "HELLO ${currentUser.displayName.split(" ")[0]}",
          style: TextStyle(
              fontSize: currentUser.displayName.length <= 30 ? 18.0 : 13.0,
              fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              googleSignIn.signOut();
              if (this.mounted) {
                setState(() {
                  isAuth = false;
                  hisLoading = false;
                  isFace = false;

                  _detectingFaces = false;
                  pictureTaked = false;
                  _bottomSheetVisible = false;
                  predictedUser = null;
                });
              }
            },
            child: Icon(
              Icons.input,
              color: Colors.white,
            ),
          ),
        ],
      );
    else
      return null;
  }

  buildUnAuthScreen() {
    return WillPopScope(
        // ignore: missing_return
        onWillPop: () {
          showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                      backgroundColor: Colors.white,
                      title: new Text("Are you sure??",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      content: new Text("Click yes to exit App",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 15.0, color: Colors.black)),
                      actions: [
                        FlatButton(
                            onPressed: () {
                              exit(0);
                            },
                            child: Text("Yes",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue))),
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("No",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue))),
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Cancel",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)))
                      ]));
        },
        child: Scaffold(
          backgroundColor: Colors.orange[200],
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(height: MediaQuery.of(context).size.height / 4.5),
              Container(
                padding: EdgeInsets.all(32),
                height: MediaQuery.of(context).size.height / 2,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("images/5.png"),
                  ),
                ),
                alignment: Alignment.center,
              ),
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: GestureDetector(
                    onTap: login,
                    child: Container(
                      height: 50.0,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: Center(
                        child: Text(
                          "Sign in with Google",
                          style: TextStyle(
                              fontFamily: "RussoOne",
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              (hisLoading == true) ? circularProgress() : Text("")
            ],
          ),
        ));
  }

  _start() async {
    _initializeControllerFuture =
        _cameraService.startService(cameraDescription);
    await _initializeControllerFuture;

    setState(() {
      cameraInitializated = true;
    });

    _frameFaces();
  }

  Future _initializeControllerFuture;

  CameraService _cameraService = CameraService();

  bool cameraInitializated = false;
  bool _detectingFaces = false;
  bool pictureTaked = false;

  // switchs when the user press the camera
  bool _saving = false;
  bool _bottomSheetVisible = false;

  String imagePath;
  Size imageSize;
  Face faceDetected;

  final TextEditingController _userTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  /// draws rectangles when detects faces
  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        // if its currently busy, avoids overprocessing
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlVisionService.getFacesFromImage(image);

          if (faces != null) {
            if (faces.length > 0) {
              // preprocessing the image
              setState(() {
                faceDetected = faces[0];
              });

              if (_saving) {
                _saving = false;
                _faceNetService.setCurrentPrediction(image, faceDetected);
              }
            } else {
              setState(() {
                faceDetected = null;
              });
            }
          }

          _detectingFaces = false;
        } catch (e) {
          print(e);
          _detectingFaces = false;
        }
      }
    });
  }

  /// handles the button pressed event
  onShot() async {
    if (faceDetected == null) {
      showDialog(
          context: context,
          builder: (BuildContext context) => const AlertDialog(
                content: Text('No face detected!'),
              ));

      return false;
    } else {
      imagePath =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');

      _saving = true;

      await Future.delayed(Duration(milliseconds: 500));
      await _cameraService.cameraController.stopImageStream();
      await Future.delayed(Duration(milliseconds: 200));
      await _cameraService.takePicture(imagePath);

      setState(() {
        _bottomSheetVisible = true;
        pictureTaked = true;
      });

      return true;
    }
  }

  Future _signUp(context) async {
    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;

    setState(() {
      isFace = true;
      _detectingFaces = false;
      pictureTaked = false;
      _bottomSheetVisible = false;
    });
    Navigator.pop(context);

    usersRef
        .document(currentUser.id)
        .updateData({"Fp": password, "access": "yes"});

    /// creates a new user in the 'database'
    await _dataBaseService.saveData(user, password, predictedData);

    /// resets the face stored in the face net sevice
    this._faceNetService.setPredictedData(null);

    DocumentSnapshot doc = await usersRef.document(guser.id).get();
    currentUser = User.fromDocument(doc);
    _passwordTextEditingController.clearComposing();
    _cameraService.dispose();
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    print(password);
    print(this.predictedUser.password);

    if (currentUser.Fp == password) {
      setState(() {
        isFace = true;
        _detectingFaces = false;
        pictureTaked = false;
        _bottomSheetVisible = false;
      });
      Navigator.pop(context);

      print(" Right PASSWORD!");
      usersRef.document(currentUser.id).updateData({"access": "yes"});

      DocumentSnapshot doc = await usersRef.document(guser.id).get();
      currentUser = User.fromDocument(doc);

      /* print("sending email");
      var res = await http.get(
          'https://us-central1-joint-club.cloudfunctions.net/sendMail?dest=${currentUser.email}');
      print(res.body);
      print("sent");*/
      _passwordTextEditingController.clear();
      _cameraService.dispose();
    } else {
      print(" WRONG PASSWORD!");

      usersRef.document(currentUser.id).updateData({"access": "incorrect"});

      DocumentSnapshot doc = await usersRef.document(guser.id).get();

      setState(() {
        currentUser = User.fromDocument(doc);
      });
      Navigator.pop(context);
      _passwordTextEditingController.clear();
      _cameraService.dispose();
    }
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    return userAndPass ?? null;
  }

  upSheet(context) {
    _userTextEditingController.text = currentUser.displayName;
    return WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    isAuth = true;
                    isFace = false;

                    _detectingFaces = false;
                    pictureTaked = false;
                    _bottomSheetVisible = false;
                  });
                  _start();
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.input, color: Colors.white),
                  onPressed: () {
                    googleSignIn.signOut();
                    Navigator.pop(context);
                    if (this.mounted) {
                      setState(() {
                        isAuth = false;
                        hisLoading = false;
                        isFace = false;

                        _detectingFaces = false;
                        pictureTaked = false;
                        _bottomSheetVisible = false;
                        predictedUser = null;
                      });
                    }
                  },
                ),
              ],
              centerTitle: true,
              title: Container(
                child: Text(
                  'FaceID Setup',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )),
          body: ListView(
            padding: EdgeInsets.all(20),
            children: [
              TextField(
                controller: _userTextEditingController,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  labelText: "Name",
                  labelStyle: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                      fontFamily: "Poppins-Regular"),
                  hintText: "Enter Name",
                  hintStyle: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                      fontFamily: "Poppins-Regular"),
                ),
              ),
              TextField(
                controller: _passwordTextEditingController,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  labelText: "FaceID Passcode",
                  labelStyle: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                      fontFamily: "Poppins-Regular"),
                  hintText: "Enter Passcode",
                  hintStyle: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                      fontFamily: "Poppins-Regular"),
                ),
                obscureText: true,
              ),
              Text(""),
              Container(
                  width: 250,
                  alignment: Alignment.center,
                  child: RaisedButton(
                    child: Text('Save Face-ID'),
                    color: Colors.black,
                    onPressed: () async {
                      if (_passwordTextEditingController.text.trim().length > 0)
                        await _signUp(context);
                      else
                        showDialog(
                            context: context,
                            builder: (_) => new AlertDialog(
                                  title: new Text("Error",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 17.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  content: Text("Password can't be empty",
                                      style: TextStyle(
                                          fontSize: 17, color: Colors.white)),
                                ));
                    },
                  )),
              Container(),
              Text(""),
            ],
          ),
        ),
        // ignore: missing_return
        onWillPop: () {
          Navigator.pop(context);
          setState(() {
            isAuth = true;
            isFace = false;

            _detectingFaces = false;
            pictureTaked = false;
            _bottomSheetVisible = false;
          });
          _start();
        });
  }

  signSheet(context) {
    _userTextEditingController.text = currentUser.displayName;
    return WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.orange[200],
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isAuth = true;
                  isFace = false;

                  _detectingFaces = false;
                  pictureTaked = false;
                  _bottomSheetVisible = false;
                });
                _start();
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.input, color: Colors.white),
                onPressed: () {
                  googleSignIn.signOut();
                  Navigator.pop(context);
                  if (this.mounted) {
                    setState(() {
                      isAuth = false;
                      hisLoading = false;
                      isFace = false;

                      _detectingFaces = false;
                      pictureTaked = false;
                      _bottomSheetVisible = false;
                      predictedUser = null;
                    });
                  }
                },
              ),
            ],
            centerTitle: true,
            title: predictedUser != null
                ? Container(
                    child: Text(
                      'Hello ' + predictedUser.user.split(" ")[0] + ' 😄',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(
                    child: Text(
                    'User not found 😞',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  )),
          ),
          body: ListView(
            padding: EdgeInsets.all(20),
            children: [
              predictedUser == null
                  ? Container()
                  : Center(
                      child: Text(
                      'Enter Passcode',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    )),
              predictedUser == null
                  ? Container()
                  : TextField(
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                      controller: _passwordTextEditingController,
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        labelText: "FaceID Passcode",
                        labelStyle: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black54,
                            fontFamily: "Poppins-Regular"),
                        hintText: "Enter Passcode",
                        hintStyle: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black54,
                            fontFamily: "Poppins-Regular"),
                      ),
                      obscureText: true,
                    ),
              Text(""),
              predictedUser != null
                  ? Container(
                      width: 250,
                      alignment: Alignment.center,
                      child: RaisedButton(
                        child: Text('Provide Access'),
                        color: Colors.black,
                        onPressed: () async {
                          _signIn(context);
                        },
                      ))
                  : Container(),
              Text(""),
            ],
          ),
        ),

        // ignore: missing_return
        onWillPop: () {
          Navigator.pop(context);
          setState(() {
            isAuth = true;
            isFace = false;

            _detectingFaces = false;
            pictureTaked = false;
            _bottomSheetVisible = false;
          });
          _start();
        });
  }

  Userx predictedUser;

  face_signin() {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;

    return WillPopScope(
      child: Scaffold(
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (pictureTaked) {
                return Container(
                  width: width,
                  child: Transform(
                      alignment: Alignment.center,
                      child: Image.file(File(imagePath)),
                      transform: Matrix4.rotationY(mirror)),
                );
              } else {
                return Transform.scale(
                  scale: 1.0,
                  child: AspectRatio(
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Container(
                          width: width,
                          height: width /
                              _cameraService.cameraController.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              CameraPreview(_cameraService.cameraController),
                              CustomPaint(
                                painter: FacePainter(
                                    face: faceDetected, imageSize: imageSize),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlatButton(
                      onPressed: () {
                        googleSignIn.signOut();

                        if (this.mounted) {
                          setState(() {
                            isAuth = false;
                            hisLoading = false;
                            isFace = false;

                            _detectingFaces = false;
                            pictureTaked = false;
                            _bottomSheetVisible = false;
                            predictedUser = null;
                          });
                        }
                      },
                      child: Icon(Icons.input)),
                  FloatingActionButton.extended(
                    label: Text('Sign in'),
                    icon: Icon(Icons.camera_alt),
                    // Provide an onPressed callback.
                    onPressed: () async {
                      try {
                        // Ensure that the camera is initialized.
                        await _initializeControllerFuture;
                        // onShot event (takes the image and predict output)
                        bool faceDetected = await onShot();

                        if (faceDetected) {
                          var userAndPass = _predictUser();
                          if (userAndPass != null) {
                            this.predictedUser = Userx.fromDB(userAndPass);
                          }

                          showModalBottomSheet(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30.0),
                                      topRight: Radius.circular(30.0))),
                              context: context,
                              builder: (BuildContext c) {
                                return signSheet(context);
                              });
                        }
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        print(e);
                      }
                    },
                  ),
                  FlatButton(onPressed: () {}, child: Icon(Icons.flash_on)),
                ],
              )
            : Container(),
      ),

      // ignore: missing_return
      onWillPop: () {
        googleSignIn.signOut();

        if (this.mounted) {
          setState(() {
            isAuth = false;
            hisLoading = false;
            isFace = false;

            _detectingFaces = false;
            pictureTaked = false;
            _bottomSheetVisible = false;
            predictedUser = null;
          });
        }
      },
    );
  }

  face_signup() {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    return WillPopScope(
      child: Scaffold(
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (pictureTaked) {
                  return Container(
                    width: width,
                    child: Transform(
                        alignment: Alignment.center,
                        child: Image.file(File(imagePath)),
                        transform: Matrix4.rotationY(mirror)),
                  );
                } else {
                  return Transform.scale(
                    scale: 1.0,
                    child: AspectRatio(
                      aspectRatio: MediaQuery.of(context).size.aspectRatio,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Container(
                            width: width,
                            height: width /
                                _cameraService
                                    .cameraController.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CameraPreview(_cameraService.cameraController),
                                CustomPaint(
                                  painter: FacePainter(
                                      face: faceDetected, imageSize: imageSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: !_bottomSheetVisible
              ? FloatingActionButton.extended(
                  label: Text('Sign up'),
                  icon: Icon(Icons.camera_alt),
                  // Provide an onPressed callback.
                  onPressed: () async {
                    try {
                      // Ensure that the camera is initialized.
                      await _initializeControllerFuture;
                      // onShot event (takes the image and predict output)
                      bool faceDetected = await onShot();

                      if (faceDetected) {
                        showModalBottomSheet(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30.0),
                                    topRight: Radius.circular(30.0))),
                            context: context,
                            builder: (BuildContext c) {
                              return upSheet(context);
                            });
                      }
                    } catch (e) {
                      // If an error occurs, log the error to the console.
                      print(e);
                    }
                  },
                )
              : Container()),

      // ignore: missing_return
      onWillPop: () {
        googleSignIn.signOut();

        if (this.mounted) {
          setState(() {
            isAuth = false;
            hisLoading = false;
            isFace = false;

            _detectingFaces = false;
            pictureTaked = false;
            _bottomSheetVisible = false;
            predictedUser = null;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAuth == false)
      return buildUnAuthScreen();
    else if (isAuth == true &&
        isFace == false &&
        currentUser.face_file == "" &&
        currentUser.access == "no")
      return face_signup();
    else if (isAuth == true &&
        isFace == false &&
        currentUser.face_file != "" &&
        currentUser.access == "no")
      return face_signin();
    else if (isAuth == true &&
        isFace == false &&
        currentUser.face_file != "" &&
        currentUser.access == "incorrect")
      return face();
    else if (isAuth == true && isFace == true && currentUser != null)
      return buildAuthScreen();
  }
}

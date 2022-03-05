// A screen that allows users to take a picture using a given camera.
import 'dart:async';
import 'dart:io';
import 'package:Joint/FACE/pages/db/database.dart';
import 'package:Joint/FACE/pages/widgets/FacePainter.dart';
import 'package:Joint/FACE/pages/widgets/auth-action-button.dart';
import 'package:Joint/FACE/services/camera.service.dart';
import 'package:Joint/FACE/services/facenet.service.dart';
import 'package:Joint/FACE/services/ml_vision_service.dart';
import 'package:Joint/pages/home.dart';
import 'package:Joint/pages/models/user.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SignIn extends StatefulWidget {
  final CameraDescription cameraDescription;

  const SignIn({
    Key key,
    @required this.cameraDescription,
  }) : super(key: key);

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  /// Service injection
  CameraService _cameraService = CameraService();
  MLVisionService _mlVisionService = MLVisionService();
  FaceNetService _faceNetService = FaceNetService();

  Future _initializeControllerFuture;

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
      TextEditingController(text: currentUser.displayName);
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  Userx predictedUser;

  @override
  void initState() {
    super.initState();

    /// starts the camera & start framing faces
    _start();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraService.dispose();
    super.dispose();
  }

  /// starts the camera & start framing faces
  _start() async {
    _initializeControllerFuture =
        _cameraService.startService(widget.cameraDescription);
    await _initializeControllerFuture;

    setState(() {
      cameraInitializated = true;
    });

    _frameFaces();
  }

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
    }
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    return userAndPass ?? null;
  }

  signSheet(context) {
    return Container(
      padding: EdgeInsets.all(20),
      height: 300,
      child: Column(
        children: [
          predictedUser != null
              ? Container(
                  child: Text(
                    'Welcome back, ' + predictedUser.user + '! 😄',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : Container(
                  child: Text(
                  'User not found 😞',
                  style: TextStyle(fontSize: 20),
                )),
          Container(),
          predictedUser == null
              ? Container()
              : TextField(
                  controller: _passwordTextEditingController,
                  decoration:
                      InputDecoration(labelText: "Face-ID-Secret-Password"),
                  obscureText: true,
                ),
          predictedUser != null
              ? RaisedButton(
                  child: Text('Provide Access'),
                  onPressed: () async {
                    _signIn(context);
                  },
                )
              : Container(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
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
          ? FloatingActionButton.extended(
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
            )
          : Container(),
    );
  }
}

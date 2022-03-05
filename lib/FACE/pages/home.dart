import 'package:Joint/FACE/pages/db/database.dart';
import 'package:Joint/FACE/pages/sign-in.dart';
import 'package:Joint/FACE/pages/sign-up.dart';
import 'package:Joint/FACE/services/facenet.service.dart';
import 'package:Joint/FACE/services/ml_vision_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Services injection
  FaceNetService _faceNetService = FaceNetService();
  MLVisionService _mlVisionService = MLVisionService();
  DataBaseService _dataBaseService = DataBaseService();
  String x = "";
  dynamic data = {};

  CameraDescription cameraDescription;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    _startUp();
  }

  /// 1 Obtain a list of the available cameras on the device.
  /// 2 loads the face net model
  _startUp() async {
    _setLoading(true);

    data = _dataBaseService.db;

    setState(() {
      if (data.length == 0)
        x = "empty";
      else
        x = "present";
    });
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

    _setLoading(false);
  }

  // shows or hides the circular progress indicator
  _setLoading(bool value) {
    setState(() {
      loading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face recognition auth'),
        leading: Container(),
      ),
      body: !loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Sign In'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => SignIn(
                            cameraDescription: cameraDescription,
                          ),
                        ),
                      );
                    },
                  ),
                  RaisedButton(
                    child: Text('Sign Up'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => SignUp(
                            cameraDescription: cameraDescription,
                          ),
                        ),
                      );
                    },
                  ),
                  RaisedButton(
                    child: Text('Clean DB'),
                    onPressed: () {
                      _dataBaseService.cleanDB();
                    },
                  ),
                  Text(
                    "x",
                    style: TextStyle(color: Colors.black),
                  )
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

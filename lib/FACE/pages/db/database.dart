import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:Joint/pages/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

String em =
    "https://firebasestorage.googleapis.com/v0/b/joint-club.appspot.com/o/FaceID%2Fempty.json?alt=media&token=c4d6b869-5cfd-43ed-b890-245b4e7011f7";

class DataBaseService {
  // singleton boilerplate
  static final DataBaseService _cameraServiceService =
      DataBaseService._internal();

  factory DataBaseService() {
    return _cameraServiceService;
  }
  // singleton boilerplate
  DataBaseService._internal();

  /// file that stores the data on filesystem
  File jsonFile;

  /// Data learned on memory
  Map<String, dynamic> _db = Map<String, dynamic>();
  Map<String, dynamic> get db => this._db;

  /// loads a simple json file.
  Future loadDB() async {
    var tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';

    if (currentUser.face_file == "") {
      jsonFile = new File(_embPath);
    } else {
      File f = await urlToFile(currentUser.face_file);
      jsonFile = new File(f.path);
    }

    //  jsonFile = new File(_embPath);

    if (jsonFile.existsSync()) {
      _db = json.decode(jsonFile.readAsStringSync());
    }
  }

  Future<File> urlToFile(String imageUrl) async {
// generate random number.
    var rng = new Random();
// get temporary directory of device.
    Directory tempDir = await getTemporaryDirectory();
// get temporary path from temporary directory.
    String tempPath = tempDir.path;
// create a new file in temporary path with random file name.
    File file = new File('$tempPath' + (rng.nextInt(100)).toString() + '.png');
// call http.get method and pass imageUrl into it to get response.
    http.Response response = await http.get(imageUrl);
// write bodyBytes received in response to file.
    await file.writeAsBytes(response.bodyBytes);
// now return the file which is created with random name in
// temporary directory and image bytes from response is written to // that file.
    return file;
  }

  /// [Name]: name of the new user
  /// [Data]: Face representation for Machine Learning model
  Future saveData(String user, String password, List modelData) async {
    String userAndPass = user + ':' + password;
    _db[userAndPass] = modelData;
    print(_db);
    json.encode(_db);
    jsonFile.writeAsStringSync(json.encode(_db));
    print("PATHHHH  : " + jsonFile.path);

    //Cloud-Storage
    StorageUploadTask uploadTask = storageRef
        .child("FaceID")
        .child("/${currentUser.email}")
        .child("${currentUser.displayName}.json")
        .putFile(jsonFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    usersRef.document(currentUser.id).updateData({"face_file": downloadUrl});
  }

  /// deletes the created users
  cleanDB() {
    this._db = Map<String, dynamic>();
    jsonFile.writeAsStringSync(json.encode({}));
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/widgets/header.dart';
import './models/user.dart';
import './home.dart';
import './widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  File file;
  File temp;
  bool isUploading = false;
  bool isLoc = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
      this.temp = file;
    });

    _cropImage();
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
      this.temp = file;
    });

    _cropImage();
  }

  _cropImage() async {
    File croppedFile = await ImageCropper().cropImage(
        sourcePath: temp.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
              ]
            : [
                CropAspectRatioPreset.square,
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.grey[900],
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));

    setState(() {
      if (croppedFile != null) file = croppedFile;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: Colors.white,
          children: <Widget>[
            SimpleDialogOption(
                child: Text("OPEN CAMERA",
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("IMPORT FROM GALLERY",
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("CANCEL",
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Scaffold buildSplashScreen() {
    return Scaffold(
        backgroundColor: Colors.orange[200],
        appBar: header(context, titleText: "Upload"),
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.portrait,
                size: 250,
                color: Colors.black,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: RaisedButton(
                    elevation: 10.0,
                    child: Text(
                      "Upload Image",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25.0,
                      ),
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                    onPressed: () => selectImage(context)),
              ),
            ],
          ),
        ));
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef
        .document(currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": currentUser.id,
      "username": currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  fun() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("POST UPLOADED!!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "JustAnotherHand",
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              // content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
            ));
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
      if (locationController.text.trim() == "")
        locationController.text = "Unknown Location";
      else
        locationController.text = "at " + locationController.text;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );

    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      temp = null;
      isUploading = false;
      postId = Uuid().v4();
    });
    fun();
  }

  WillPopScope buildUploadForm() {
    return WillPopScope(
        // ignore: missing_return
        onWillPop: () {
          clearImage();
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading:
                IconButton(icon: Icon(Icons.arrow_back), onPressed: clearImage),
            title: Text(
              "Upload Post",
              style: TextStyle(),
            ),
            actions: [
              FlatButton(
                onPressed: isUploading ? null : () => handleSubmit(),
                child: Text(
                  "Post",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[200],
          body: ListView(
            padding: EdgeInsets.all(10),
            children: <Widget>[
              isUploading ? linearProgress() : Text(""),
              Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Card(
                      color: Colors.black,
                      child: Column(children: <Widget>[
                        ListTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  currentUser.photoUrl),
                              backgroundColor: Colors.grey,
                            ),
                            title: Text(
                              currentUser.username,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "New Post",
                              style: TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                                icon: Icon(
                                  Icons.cut,
                                  color: Colors.white,
                                ),
                                onPressed: _cropImage)),
                        AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(file),
                              ),
                            ),
                          ),
                        ),
                        Text(""),
                        Padding(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              controller: captionController,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white, width: 0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20.0)),
                                  borderSide:
                                      BorderSide(color: Colors.white, width: 0),
                                ),
                                contentPadding: EdgeInsets.all(8),
                                prefixIcon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                hintText: "Write a Caption...",
                                hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                    fontFamily: "Poppins-Regular"),
                              ),
                            )),
                        Text(""),
                        Padding(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              controller: locationController,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white, width: 0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20.0)),
                                  borderSide:
                                      BorderSide(color: Colors.white, width: 0),
                                ),
                                contentPadding: EdgeInsets.all(8),
                                prefixIcon: Icon(
                                  Icons.pin_drop,
                                  color: Colors.white,
                                ),
                                hintText: "Where was this photo taken?",
                                hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                    fontFamily: "Poppins-Regular"),
                              ),
                            )),
                        (isLoc)
                            ? Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.only(top: 10.0),
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ))
                            : Container(
                                width: 200.0,
                                height: 100.0,
                                alignment: Alignment.center,
                                child: RaisedButton.icon(
                                  label: Text(
                                    "Use Current Location",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  color: Colors.blue,
                                  onPressed: getUserLocation,
                                  icon: Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ]))),
            ],
          ),
        ));
  }

  getUserLocation() async {
    setState(() {
      isLoc = true;

      locationController.clear();
    });
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.subLocality}, ${placemark.locality}";
    setState(() {
      isLoc = false;
      locationController.text = formattedAddress;
    });
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}

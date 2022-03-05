import 'package:flutter/material.dart';
import 'package:Joint/pages/home.dart';

import '../upload.dart';

AppBar header(context,
    {bool isAppTitle = false, String titleText, removeBackButton = false}) {
  return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        isAppTitle ? "The  Joint  Club" : titleText,
        style: TextStyle(
          color: Colors.white,
          fontFamily: isAppTitle ? "MrDafoe" : "",
          fontSize: isAppTitle ? 50.0 : 22.0,
        ),
      ),
      centerTitle: true,
    );
}

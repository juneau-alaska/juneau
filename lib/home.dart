import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/appBar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

void logoutUser(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs?.clear();
  Navigator.of(context)
      .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: appBar,
      body: Column(
        children: <Widget>[
          FlatButton(
            onPressed: () {
              logoutUser(context);
            },
            color: Colors.blue.shade500,
            shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(6.0)
            ),
            child: Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white
              ),
            )
          )
        ],
      )
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/appBar.dart';
import 'package:juneau/poll.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void logoutUser(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs?.clear();
  Navigator.of(context)
      .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
}

Future<List> _getPolls() async {
  const url = 'http://localhost:4000/polls';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(
      url,
      headers: headers
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  var poll;

  @override
  void initState() {
    _getPolls().then((result){
      setState(() {
        if (result != null) {
          poll = result[result.length - 1];
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (poll == null) {return new Container();}
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: appBar,
        body: new PollWidget(poll: poll),
    );
  }
}

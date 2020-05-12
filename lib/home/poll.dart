import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<List> _getUser(userId) async {
  var url = 'http://localhost:4000/user/' + userId;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(
    url,
    headers: headers,
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }
}

Future<List> _getChoices(poll) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var options = poll['options'];
  List<Future> futures = [];
  List choices;

  for (var i = 0; i < options.length; i++) {
    var optionId = options[i];
    Future future() async {
      var response = await http.get(
        url + '/' + optionId,
        headers: headers,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        return jsonResponse;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    }
    futures.add(future());
  }

  await Future.wait(futures)
    .then((results) {
      choices = results;
    });

  return choices;
}

class PollWidget extends StatefulWidget {
  final poll;

  PollWidget({ Key key, @required this.poll }) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var user,
      choices;

  List buildPoll() {
    List<Widget> widgets = [
      Text(
        widget.poll['prompt'],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
      SizedBox(
        height: 2.0
      ),
      GestureDetector(
        child: Text(
          user['username'],
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.blue,
          ),
        ),
        onTap: () {
          print(user['email']);
        }
      ),
      SizedBox(
        height: 20.0
      ),
    ];

    if (choices.length > 0) {
      for (var i = 0; i < choices.length; i++) {
        var choice = choices[i];
        widgets.add(
          FlatButton(
            color: Colors.red,
            child: Text(
              choice['content'],
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16.0
              ),
            ),
            onPressed: () {},
          ),
        );
      }
    }
    return widgets;
  }

  @override
  void initState() {
    var poll = widget.poll;
    _getUser(poll['createdBy'])
      .then((pollUser) {
        if (pollUser != null && pollUser.length > 0) {
          user = pollUser[0];
        }
        _getChoices(poll)
          .then((pollChoices) {
            setState(() {
              if (pollChoices != null && pollChoices.length > 0) {
                choices = pollChoices;
              }
            });
        });
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (choices == null) {
      return new Container();
    }
    List widgets = buildPoll();

    return Container(
      height: 225.0,
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 25.0, 20.0, 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widgets,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

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

void vote(choice, poll) async {
  var url = 'http://localhost:4000/option/vote/' + choice['_id'];

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.put(
    url,
    headers: headers
  );

  if (response.statusCode == 200) {
    updateUserCompletedPolls(poll['_id'], choice['_id']);
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

void updateUserCompletedPolls(pollId, choiceId) async {
  const url = 'http://localhost:4000/user/';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'),
      userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(
      url + userId,
      headers: headers
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body)[0],
        completedPolls = jsonResponse['completedPolls'],
        selectedChoices = jsonResponse['selectedChoices'];


    completedPolls.add(pollId);
    selectedChoices.add(choiceId);

    var body = jsonEncode({
      'completedPolls': completedPolls,
      'selectedChoices': selectedChoices
    });

    response = await http.put(
        url + userId,
        headers: headers,
        body: body
    );

    if (response.statusCode != 200) {
      print('Request failed with status: ${response.statusCode}.');
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

class PollWidget extends StatefulWidget {
  final poll;

  PollWidget({ Key key, @required this.poll }) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var user, choices;

  List buildPoll() {
    var createdAt = DateTime.parse(widget.poll['createdAt']),
        time = timeago.format(createdAt, locale: 'en_short');

    List<Widget> widgets = [
      SizedBox(
        height: 10.0
      ),
      Text(
        widget.poll['prompt'],
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(
        height: 10.0
      ),
      Row(
        children: <Widget>[
          GestureDetector(
            child: Text(
              user['username'],
              style: TextStyle(
                fontSize: 13.0,
              ),
            ),
            onTap: () {
              print(user['email']);
            }
          ),
          SizedBox(
            width: 3.0,
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11.0,
              color: Theme.of(context).accentColor,
              wordSpacing: -3.0
            ),
          ),
        ],
      ),
      SizedBox(
          height: 15.0
      ),
    ];

    if (choices.length > 0) {
      for (var i = 0; i < choices.length; i++) {
        var choice = choices[i];
        widgets.add(
          Container(
            decoration: new BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 0.5,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: FlatButton(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                color: Colors.transparent,
                child: Text(
                  choice['content'],
                  style: TextStyle(
                    color: Colors.white, // Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w300
                  ),
                ),
                onPressed: () {
                  vote(choice, widget.poll);
                },
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  void initState() {
    _getUser(widget.poll['createdBy'])
      .then((pollUser) {
        if (pollUser != null && pollUser.length > 0) {
          user = pollUser[0];
        }
        _getChoices(widget.poll)
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
      decoration: new BoxDecoration(
        color: Theme.of(context).cardColor,
//        borderRadius: BorderRadius.circular(10),
//        border: Border.all(
//          color: Theme.of(context).accentColor,
//          width: 0.5,
//        ),
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widgets,
        ),
      ),
    );
  }
}


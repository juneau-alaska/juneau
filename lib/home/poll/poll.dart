import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:juneau/common/methods/userMethods.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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
  var user;

  PollWidget({ Key key, @required this.poll, this.user}) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var pollCreator,
      choices;

//  @override
//  void setState(fn) {
//    // TODO: implement setState
//    super.setState(fn);
//  }

  void vote(choice) async {
    var poll = widget.poll,
        url = 'http://localhost:4000/option/vote/' + choice['_id'];

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

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body),
            user = jsonResponse['user'];

        setState(() {
          widget.user[0] = user;
        });
      }
      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Widget buildPoll() {
    var createdAt = DateTime.parse(widget.poll['createdAt']),
        time = timeago.format(createdAt, locale: 'en_short');

    List<Widget> children = [
      SizedBox(
        height: 10.0
      ),
      Text(
        widget.poll['prompt'],
        style: TextStyle(
          fontFamily: 'Lato Black',
          fontSize: 20.0,
        ),
      ),
      SizedBox(
        height: 8.0
      ),
      Row(
        children: <Widget>[
          GestureDetector(
            child: Text(
              pollCreator['username'],
              style: TextStyle(
                fontSize: 14.0,
              ),
            ),
            onTap: () {
              print(pollCreator['email']);
            }
          ),
          SizedBox(
            width: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              time,
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontSize: 13.0,
                wordSpacing: -2.0,
              ),
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
        var choice = choices[i],
            poll = widget.poll,
            user = widget.user[0],
            selectedChoices = user['selectedChoices'],
            completedPolls = user['completedPolls'],
            color = Theme.of(context).primaryColor,
            voteIcon = new Align(),
            completed = false;

        if (completedPolls.indexOf(poll['_id']) >= 0 ) {
          completed = true;
        }

        if (selectedChoices.indexOf(choice['_id']) >= 0 ) {
          color = Theme.of(context).accentColor;
          voteIcon = Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.check,
              color: Theme.of(context).buttonColor,
              size: 20.0
            ),
          );
        }

        children.add(
          Container(
            decoration: new BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 0.5,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
              child: Center(
                child: FlatButton(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          choice['content'],
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1.color,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      voteIcon,
                    ],
                  ),
                  onPressed: () {
                    if (!completed) {
                      vote(choice);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      }
    }

    children.add(
      Row(
        children: <Widget>[
          Icon(
            Icons.favorite,
            color: Theme.of(context).buttonColor,
            size: 20.0,
          ),
          Icon(
            Icons.mode_comment,
            color: Theme.of(context).buttonColor,
            size: 20.0,
          ),
        ],
      )
    );

    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  void initState() {
    userMethods.getUser(widget.poll['createdBy'])
      .then((pollUser) {
        if (pollUser != null && pollUser.length > 0) {
          pollCreator = pollUser[0];
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
    return buildPoll();
  }
}


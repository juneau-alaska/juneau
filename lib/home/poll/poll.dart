import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  var pollCreator, choices;

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
      var jsonResponse = jsonDecode(response.body),
          option = jsonResponse['option'];

      for (var i = 0; i < choices.length; i++) {
        var choice = choices[i];
        if (choice['_id'] == option["_id"]) {
          choices[i] = option;
          break;
        }
      }

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

        if (mounted) {
          setState(() {
            widget.user[0] = user;
          });
        }
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
        time = timeago.format(createdAt, locale: 'en_short'),
        borderRadiusValue = 8.0;

    List<Widget> children = [
      SizedBox(
        height: 10.0
      ),
      Text(
        widget.poll['prompt'].toUpperCase(),
        style: TextStyle(
          fontFamily: 'Lato Black',
          fontSize: 20.0,
        ),
      ),
      SizedBox(
        height: 1.5
      ),
      Row(
        children: <Widget>[
          GestureDetector(
            child: Text(
              pollCreator['username'],
              style: TextStyle(
                color: Theme.of(context).highlightColor,
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
            padding: const EdgeInsets.only(top: 1.0, left: 1.0),
            child: Text(
              time,
              style: TextStyle(
                color: Theme.of(context).highlightColor,
                fontSize: 13.0,
                wordSpacing: -2.0,
              ),
            ),
          ),
        ],
      ),
      SizedBox(
          height: 8.0
      ),
    ];

    if (choices.length > 0) {
      var poll = widget.poll,
          user = widget.user[0],
          selectedChoices = user['selectedChoices'],
          completedPolls = user['completedPolls'];
      bool completed = completedPolls.indexOf(poll['_id']) >= 0;
      int totalVotes = 0;

      if (completed) {
        for (var c in choices) {
          totalVotes += c['votes'];
        }
      }

      for (var choice in choices) {
        String percentStr = "";
        Widget resultBar = new Container();

        double borderRadius = borderRadiusValue;
        int charLimit = 21;
        int stringLength = choice['content'].length < charLimit ? 0 : choice['content'].length;
        double choiceHeight = 36.0 + 12*(stringLength/charLimit);

        Color resultColor = Theme.of(context).highlightColor;
        Color resultTextColor = const Color(0xFFD7DADC);

        if (completed) {
          int votes = choice['votes'];
          double percent = votes > 0 ? votes/totalVotes : 0;
          BorderRadius radius = BorderRadius.circular(borderRadius);

          if (percent < 1.0) {
            radius = BorderRadius.only(topLeft: Radius.circular(borderRadius), bottomLeft: Radius.circular(borderRadius));
          }

          if (percent > 0) {
            percentStr = (percent * 100.0).toStringAsFixed(0) + '%';
          }

          if (selectedChoices.indexOf(choice['_id']) >= 0 ) {
//            resultColor = Theme.of(context).accentColor;
            resultTextColor = Theme.of(context).accentColor;
          }

          resultBar = new Container(
            height: choiceHeight + 1,
            width: MediaQuery.of(context).size.width * percent,
            decoration: new BoxDecoration(
              color: resultColor,
              borderRadius: radius,
              border: Border.all(
                color: Colors.transparent,
                width: 0.75,
              ),
            ),
          );
        }

        children.add(
          Stack(
            children: <Widget>[
              new Container(
                height: choiceHeight + 1,
                width: MediaQuery.of(context).size.width,
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 0.75,
                  ),
                ),
              ),
              resultBar,
              GestureDetector(
                onTap: () {
                  if (!completed) {
                    HapticFeedback.lightImpact();
                    vote(choice);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 7.5),
                  decoration: new BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 0.75,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      new Flexible(
                        child: new Column(
                          children: <Widget>[
                            Center(
                              child: Container(
                                height: choiceHeight,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0, right: 15.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      choice['content'].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: resultTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              "$percentStr ",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: resultTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        );
      }
    }

//    children.add(
//      Row(
//        children: <Widget>[
//          Icon(
//            Icons.favorite,
//            color: Theme.of(context).buttonColor,
//            size: 20.0,
//          ),
//          Icon(
//            Icons.mode_comment,
//            color: Theme.of(context).buttonColor,
//            size: 20.0,
//          ),
//        ],
//      )
//    );

    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13.0, 10.0, 13.0, 10.0),
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
            if (mounted) {
              setState(() {
                if (pollChoices != null && pollChoices.length > 0) {
                  choices = pollChoices;
                }
              });
            }
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


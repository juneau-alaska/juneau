import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  PollWidget({ Key key, @required this.poll }) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {

  var choices;

  List buildPoll(choicesList) {

    List<Widget> widgets = [
      Text(
        widget.poll['prompt'],
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0
        ),
      ),
      SizedBox(
          height: 20.0
      )
    ];

    if (choicesList.length > 0) {
      for (var i = 0; i < choicesList.length; i++) {
        var choice = choicesList[i];
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
            )
        );
      }
    }

    return widgets;
  }

  @override
  void initState() {
    _getChoices(widget.poll).then((result){
      setState(() {
        if (result != null && result.length > 0) {
          choices = result;
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

    List widgets = buildPoll(choices);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 25.0),
      child: Container(
        height: 225.0,
        decoration: new BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widgets,
          ),
        ),
      ),
    );
  }
}


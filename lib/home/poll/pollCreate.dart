import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:juneau/common/components/inputComponent.dart';

void createChoices(prompt, choices) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body, response;

  List<Future> futures = [];

  for (var i = 0; i < choices.length; i++) {
    Future future() async {
      body = jsonEncode({
        'content': choices[i]
      });

      response = await http.post(
          url,
          headers: headers,
          body: body
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        print(jsonResponse);
        return jsonResponse['_id'];
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    }
    futures.add(future());
  }

  await Future.wait(futures)
      .then((results) {
        createPoll(prompt, results);
      });
}

void createPoll(prompt, choiceIds) async {
  const url = 'http://localhost:4000/poll';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'),
      userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  print('userId');
  print(prefs.getString('userId'));

  var body = jsonEncode({
    'prompt': prompt,
    'options': choiceIds,
    'createdBy': userId
  });

  var response = await http.post(
      url,
      headers: headers,
      body: body
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }

}

class PollCreate extends StatefulWidget {
  @override
  _PollCreateState createState() => _PollCreateState();
}

class _PollCreateState extends State<PollCreate> {
  InputComponent questionInput = new InputComponent(hintText: 'Type a question...', obscureText: false);

  List<InputComponent> inputComponents = [
    new InputComponent(hintText: 'Create an option...', obscureText: false),
    new InputComponent(hintText: 'Create an option...', obscureText: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget> [
          SizedBox(
              height: 100.0
          ),
          questionInput,
          SizedBox(
              height: 30.0
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: inputComponents,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: FlatButton(
              onPressed: () {
                setState(() {
                  inputComponents.add(new InputComponent(hintText: 'Create an option...', obscureText: false));
                });
              },
              child: Text(
                'Add Option',
                style: TextStyle(
                  color: Theme.of(context).buttonColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: FlatButton(
              onPressed: () {
                var prompt  = questionInput.controller.text,
                    choices = [];

                for (var i=0; i<inputComponents.length; i++) {
                  InputComponent inputComponent = inputComponents[i];
                  choices.add(inputComponent.controller.text);
                }
                createChoices(prompt, choices);
              },
              color: Theme.of(context).buttonColor,
              child: Text(
                'Submit',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    var jsonResponse = jsonDecode(response.body),
        pollId = jsonResponse['_id'];

    updateUserCreatedPolls(pollId);
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

void updateUserCreatedPolls(pollId) async {
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
        createdPolls = jsonResponse['createdPolls'];

    createdPolls.add(pollId);

    var body = jsonEncode({
      'createdPolls': createdPolls
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

class PollCreate extends StatefulWidget {
  @override
  _PollCreateState createState() => _PollCreateState();
}

class _PollCreateState extends State<PollCreate> {
  InputComponent questionInput = new InputComponent(
      hintText: 'Ask a question...',
      obscureText: false,
      maxLines: 4,
      borderColor: Colors.transparent,
      padding: 0.0,
  );

  List<InputComponent> inputComponents = [
    new InputComponent(hintText: 'Option #1', obscureText: false),
    new InputComponent(hintText: 'Option #2', obscureText: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget> [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 65.0, 15.0, 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  "Create New Poll",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    var prompt  = questionInput.controller.text,
                        choices = [];

                    for (var i=0; i<inputComponents.length; i++) {
                      InputComponent inputComponent = inputComponents[i];
                      choices.add(inputComponent.controller.text);
                    }
                    createChoices(prompt, choices);
                  },
                  child: Text(
                    "Create",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          questionInput,
          SizedBox(
            height: 30.0
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              children: <Widget>[
                Text(
                  "Add Options",
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: Text(
                    "(max 9)",
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10.0
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: inputComponents,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.5),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      width: 0.5,
                      color: Theme.of(context).hintColor
                  )
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    var inputCount = inputComponents.length;
                    var optionNum = inputCount + 1;

                    print(inputCount);
                    if (inputCount < 9) {
                      inputComponents.add(
                        new InputComponent(
                          hintText: 'Option #$optionNum',
                          obscureText: false,
                        )
                      );
                    }
                  });
                },

                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11.0, 12.0, 11.0, 12.0),
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 25.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

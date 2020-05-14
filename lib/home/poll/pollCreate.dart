import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:juneau/common/components/inputComponent.dart';

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
                print(questionInput.controller.text);
                for (var i=0; i<inputComponents.length; i++) {
                  InputComponent inputComponent = inputComponents[i];
                  print(inputComponent.controller.text);
                }
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/components/inputComponent.dart';

import 'package:email_validator/email_validator.dart';
import 'package:juneau/common/methods/validator.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void signup(email, username, password, context) async {
  const url = 'http://localhost:4000/signup';
  const headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  var body = jsonEncode({'email': email, 'username': username, 'password': password});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), token = jsonResponse['token'], user = jsonResponse['user'];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (token != null) {
      prefs.setBool('isLoggedIn', true);
      prefs.setString('token', token);
    }

    if (user != null) {
      prefs.setString('userId', user['_id']);
    }

    Navigator.pushNamed(context, '/home');
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isUsernameValid = false;

  @override
  Widget build(BuildContext context) {
    InputComponent emailInput = new InputComponent(hintText: 'Email');
    final emailController = emailInput.controller;

    InputComponent usernameInput = new InputComponent(hintText: 'Username');
    final usernameController = usernameInput.controller;

    InputComponent passwordInput = new InputComponent(hintText: 'Password', obscureText: true);
    final passwordController = passwordInput.controller;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 40.0),
            Padding(
              padding: const EdgeInsets.fromLTRB(80.0, 80.0, 80.0, 40.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontFamily: 'Lato Black',
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            emailInput,
            usernameInput,
            passwordInput,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: FlatButton(
                onPressed: () {
                  String email = emailController.text;
                  String password = passwordController.text;
                  String username = usernameController.text;

                  _isPasswordValid = validator.validatePassword(password);
                  _isEmailValid = EmailValidator.validate(email);
                  _isUsernameValid = validator.validateUsername(username);

                  if (_isPasswordValid && _isEmailValid && _isUsernameValid) {
                    signup(email, username, password, context);
                  }
                },
                color: Theme.of(context).buttonColor,
                shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Theme.of(context).backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: FlatButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Theme.of(context).buttonColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

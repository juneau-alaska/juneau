import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:email_validator/email_validator.dart';
import 'package:juneau/common/methods/validator.dart';

import 'package:juneau/common/components/inputComponent.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void login(email, password, context) async {
  email = email.trimRight();

  const url = 'http://localhost:4000/login';
  const headers = {HttpHeaders.contentTypeHeader: 'application/json'};

  var body;

  if (EmailValidator.validate(email)) {
    body = jsonEncode({'email': email, 'password': password});
  } else {
    body = jsonEncode({'username': email, 'password': password});
  }

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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isUsernameValid = false;

  @override
  Widget build(BuildContext context) {
    InputComponent emailInput = new InputComponent(hintText: 'Username or email');
    final emailController = emailInput.controller;

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
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                        fontFamily: 'Lato Black',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            emailInput,
            passwordInput,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4.0),
              child: Container(
                height: 40.0,
                child: FlatButton(
                  onPressed: () {
                    print('');
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Theme.of(context).buttonColor,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              child: FlatButton(
                onPressed: () {
                  String email = emailController.text;
                  String password = passwordController.text;

                  _isPasswordValid = validator.validatePassword(password);
                  _isEmailValid = EmailValidator.validate(email);
                  _isUsernameValid = validator.validateUsername(email);

                  if (_isPasswordValid && (_isEmailValid || _isUsernameValid)) {
                    login(email, password, context);
                  }
                },
                color: Theme.of(context).buttonColor,
                shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(6.0)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    'Log In',
                    style: TextStyle(color: Theme.of(context).backgroundColor),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: FlatButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(
                  'Sign Up',
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

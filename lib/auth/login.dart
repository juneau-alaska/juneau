import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/appBar.dart';

import 'package:email_validator/email_validator.dart';
import 'package:juneau/auth/validator.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';


void login(email, password, context) async {
  const url = 'http://localhost:4000/login';
  const headers = {
    HttpHeaders.contentTypeHeader : 'application/json'
  };

  var body;

  if (EmailValidator.validate(email)) {
    body = jsonEncode({
      'email': email,
      'password': password
    });
  } else {
    body = jsonEncode({
      'username': email,
      'password': password
    });
  }

  var response = await http.post(
    url,
    headers: headers,
    body: body
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    prefs.setBool('token', jsonResponse.token);

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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordValid = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: appBar,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 40.0
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(80.0, 0.0, 80.0, 40.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'JUNEAU',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
            child: Container(
              height: 50.0,
              child: Opacity(
                opacity: 0.8,
                child: TextField(
                  style: new TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username or email',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.white70),
                    fillColor: Colors.white10,
                    filled: true,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30, width: 1.0),
                    ),
                  ),
                  controller: emailController,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
            child: Container(
              height: 50.0,
              child: Opacity(
                opacity: 0.8,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: new TextStyle(color: Colors.white),
                  onChanged: (text) {
                    setState(() {
                      _isPasswordValid = true;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.white70),
                    fillColor: Colors.white10,
                    filled: true,
                    errorText: _isPasswordValid ? null : "Password must be at least 6 characters, contain 1 capital and 1 lowercase, 1 number and 1 special character",
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30, width: 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                      color: Colors.blue.shade500,
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

                setState(() {
                  _isPasswordValid = passwordValidator.validate(password);
                });

                if (_isPasswordValid && email != '') {
                  login(email, password, context);
                }
              },
              color: Colors.blue.shade500,
              shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(6.0)
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.white,
                  ),
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
                  color: Colors.blue.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/appBar.dart';

import 'package:email_validator/email_validator.dart';
import 'package:juneau/auth/validator.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void signup(email, username, password, context) async {
  const url = 'http://localhost:4000/signup';
  const headers = {
    HttpHeaders.contentTypeHeader : 'application/json'
  };
  var body = jsonEncode({
    'email': email,
    'username': username,
    'password': password
  });

  var response = await http.post(
      url,
      headers: headers,
      body: body
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    prefs.setString('token', jsonResponse['token']);

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
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordValid = true;
  bool _isEmailValid = true;

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
                'SIGN UP',
                style: TextStyle(
                  fontSize: 20,
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
                  onChanged: (text) {
                    setState(() {
                      _isEmailValid = true;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.white70),
                    errorText: _isEmailValid ? null : "Invalid Email",
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
//                  onChanged: (text) {
//                    setState(() {
//                      _isEmailValid = true;
//                    });
//                  },
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.white70),
                    fillColor: Colors.white10,
                    filled: true,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30, width: 1.0),
                    ),
                  ),
                  controller: usernameController,
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
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
            child: FlatButton(
              onPressed: () {
                String email = emailController.text;
                String password = passwordController.text;
                String username = usernameController.text;

                setState(() {
                  _isPasswordValid = passwordValidator.validate(password);
                  _isEmailValid = EmailValidator.validate(email);
                });

                if (_isPasswordValid && _isEmailValid) {
                  signup(email, username, password, context);
                }
              },
              color: Theme.of(context).buttonColor,
              shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(6.0)
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  'Sign Up',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
    );
  }
}
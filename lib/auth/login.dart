import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/auth/forgotPassword.dart';
import 'package:juneau/common/api.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/methods/validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void login(email, password, context) async {
  email = email.trimRight();

  String url = API_URL + 'login';
  const headers = {HttpHeaders.contentTypeHeader: 'application/json'};

  var body;

  if (EmailValidator.validate(email)) {
    body = jsonEncode({'email': email, 'password': password});
  } else {
    body = jsonEncode({'username': email, 'password': password});
  }

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body),
        token = jsonResponse['token'],
        user = jsonResponse['user'];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (token != null) {
      prefs.setBool('isLoggedIn', true);
      prefs.setString('token', token);
    }

    if (user != null) {
      prefs.setString('userId', user['_id']);
    }

    Navigator.pushNamed(context, '/main');
  } else {
    return showAlert(context, 'Incorrect email, username or password.');
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  InputComponent emailInput;
  TextEditingController emailController;
  InputComponent passwordInput;
  TextEditingController passwordController;

  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isUsernameValid = false;
  bool pending = false;

  @override
  void initState() {
    emailInput = new InputComponent(hintText: 'Username or email');
    emailController = emailInput.controller;

    passwordInput = new InputComponent(hintText: 'Password', obscureText: true);
    passwordController = passwordInput.controller;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/loginSelect');
                },
                child: Icon(Icons.arrow_back_ios, size: 20.0),
              ),
              Text(
                'LOGIN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Container()
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 50.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENTER LOGIN INFO',
                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                    child: emailInput,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: passwordInput,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 23.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
                      return ForgotPasswordPage();
                    }));
                  },
                  child: Text(
                    'Trouble logging in?',
                    style: TextStyle(
                      color: Theme.of(context).highlightColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            RawMaterialButton(
              onPressed: () {
                if (pending) {
                  return showAlert(context, "You're going too fast.", true);
                }

                pending = true;
                Timer(Duration(milliseconds: 3000), () {
                  pending = false;
                });

                String email = emailController.text.trim();
                String password = passwordController.text.trim();

                _isPasswordValid = validator.validatePassword(password);
                _isEmailValid = EmailValidator.validate(email);
                _isUsernameValid = validator.validateUsername(email);

                if (_isPasswordValid && (_isEmailValid || _isUsernameValid)) {
                  login(email, password, context);
                } else {
                  return showAlert(context, 'Incorrect email, username or password.');
                }
              },
              constraints: BoxConstraints(),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              fillColor: Theme.of(context).buttonColor,
              elevation: 0.0,
              child: Text(
                'Log in',
                style: TextStyle(
                  color: Theme.of(context).backgroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).backgroundColor,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

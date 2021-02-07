import 'dart:convert';
import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/validator.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:shared_preferences/shared_preferences.dart';

void signUp(email, username, password, context) async {
  const url = 'http://localhost:4000/signUp';
  const headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  var body = jsonEncode({'email': email, 'username': username, 'password': password});

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
    var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
    if (msg == null) {
      msg = 'Something went wrong, please try again';
    }
    return showAlert(context, msg);
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  InputComponent emailInput;
  TextEditingController emailController;
  InputComponent usernameInput;
  TextEditingController usernameController;
  InputComponent passwordInput;
  TextEditingController passwordController;

  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isUsernameValid = false;

  String currentStep = 'email';

  @override
  void initState() {
    emailInput = new InputComponent(hintText: 'Email address');
    emailController = emailInput.controller;

    usernameInput = new InputComponent(
      hintText: 'Username',
      maxLength: 30,
      inputFormatters: [FilteringTextInputFormatter.allow(new RegExp("[0-9A-Za-z_.]"))],
    );
    usernameController = usernameInput.controller;

    passwordInput = new InputComponent(
      hintText: 'Password',
      obscureText: true,
    );
    passwordController = passwordInput.controller;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> currentStepWidgets = [];

    if (currentStep == 'email') {
      currentStepWidgets = [
        Padding(
          padding: const EdgeInsets.only(top: 50.0, bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ENTER A VALID EMAIL ADDRESS',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
                child: emailInput,
              ),
            ],
          ),
        ),
        FlatButton(
          onPressed: () async {
            String email = emailController.text.trim();
            _isEmailValid = EmailValidator.validate(email);

            if (!_isEmailValid) {
              return showAlert(context, 'Invalid email address');
            } else {
              var existingUser = await userMethods.getUserByEmail(email);

              if (existingUser != null) {
                return showAlert(context, 'Email address already in use');
              }

              setState(() {
                currentStep = 'password';
              });
            }
          },
          color: Theme.of(context).buttonColor,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Next',
              style: TextStyle(
                color: Theme.of(context).backgroundColor,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: Theme.of(context).buttonColor, width: 1, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(50)),
        )
      ];
    }

    if (currentStep == 'password') {
      currentStepWidgets = [
        Padding(
          padding: const EdgeInsets.only(top: 50.0, bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CREATE A PASSWORD',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
                child: passwordInput,
              ),
            ],
          ),
        ),
        FlatButton(
          onPressed: () {
            String password = passwordController.text.trim();
            _isPasswordValid = validator.validatePassword(password);

            if (password.length < 6 || password.length > 40) {
              return showAlert(context, 'Password must be between 6-40 characters.');
            } else if (!_isPasswordValid) {
              return showAlert(context, 'Password contains invalid characters.');
            } else {
              setState(() {
                currentStep = 'username';
              });
            }
          },
          color: Theme.of(context).buttonColor,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Next',
              style: TextStyle(
                color: Theme.of(context).backgroundColor,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: Theme.of(context).buttonColor, width: 1, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(50)),
        )
      ];
    }

    if (currentStep == 'username') {
      currentStepWidgets = [
        Padding(
          padding: const EdgeInsets.only(top: 50.0, bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CREATE A USERNAME',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
                child: usernameInput,
              ),
            ],
          ),
        ),
        FlatButton(
          onPressed: () async {
            String username = usernameController.text.trim().toLowerCase();

            var existingUser = await userMethods.getUserByUsername(username);

            if (existingUser != null) {
              return showAlert(context, 'Username already in use');
            }

            _isUsernameValid = validator.validateUsername(username);

            if (!_isUsernameValid) {
              return showAlert(context, 'Username contains invalid characters.');
            } else {
              signUp(emailController.text, username, passwordController.text, context);
            }
          },
          color: Theme.of(context).accentColor,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Sign up',
              style: TextStyle(
                color: Theme.of(context).backgroundColor,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: Theme.of(context).accentColor, width: 1, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(50)),
        )
      ];
    }

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
                  if (currentStep == 'email') {
                    Navigator.pushNamed(context, '/signUpSelect');
                  } else if (currentStep == 'password') {
                    setState(() {
                      currentStep = 'email';
                    });
                  } else if (currentStep == 'username') {
                    setState(() {
                      currentStep = 'password';
                    });
                  }
                },
                child: Icon(Icons.arrow_back_ios, size: 20.0),
              ),
              Text(
                'SIGN UP',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Container()
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: currentStepWidgets),
          ],
        ),
      ),
    );
  }
}

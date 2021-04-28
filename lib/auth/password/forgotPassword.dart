import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:juneau/auth/password/resetPassword.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/methods/userMethods.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  InputComponent emailInput;
  TextEditingController emailController;

  bool _isEmailValid = false;
  bool _isButtonDisabled = false;

  Timer _debounce;

  _onPressed() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_isButtonDisabled) {
        return;
      }
      _isButtonDisabled = true;

      String email = emailController.text.trim();

      _isEmailValid = EmailValidator.validate(email);

      if (!_isEmailValid) {
        _isButtonDisabled = false;
        return showAlert(context, 'Not a valid email address');
      }

      var response = await userMethods.requestPassword(email);
      bool success = response['success'];
      showAlert(context, response['msg'], success);
      if (success) {
        Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
          return ResetPasswordPage();
        }));
      }
    });
  }

  @override
  void initState() {
    emailInput = new InputComponent(hintText: 'Email');
    emailController = emailInput.controller;

    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        brightness: Theme.of(context).brightness,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 25.0,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TROUBLE LOGGING IN?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 30.0),
              child: emailInput,
            ),
            RawMaterialButton(
              onPressed: _onPressed,
              constraints: BoxConstraints(),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              fillColor: Theme.of(context).buttonColor,
              elevation: 0.0,
              child: Text(
                'Reset Password',
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

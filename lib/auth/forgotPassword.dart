import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/userMethods.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  InputComponent emailInput;
  TextEditingController emailController;

  bool _isEmailValid = false;

  @override
  void initState() {
    emailInput = new InputComponent(hintText: 'Email');
    emailController = emailInput.controller;

    super.initState();
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
            color: Theme.of(context).buttonColor,
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
              padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
              child: emailInput,
            ),
            FlatButton(
              onPressed: () {
                String email = emailController.text.trim();

                _isEmailValid = EmailValidator.validate(email);

                if (!_isEmailValid) {
                  return showAlert(context, 'Not a valid email address');
                }

                userMethods.resetPassword(email);
                showAlert(context, 'Reset link has been sent to $email', true);
              },
              color: Theme.of(context).buttonColor,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Theme.of(context).backgroundColor,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).buttonColor, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(50)),
            ),
          ],
        ),
      ),
    );
  }
}

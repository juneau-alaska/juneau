import 'package:flutter/material.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/accountMethods.dart';
import 'package:juneau/common/methods/validator.dart';

class ResetPasswordPage extends StatefulWidget {
  final userId;
  final token;

  ResetPasswordPage({
    Key key,
    @required this.userId,
    this.token,
  }) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  InputComponent passwordInput;
  TextEditingController passwordController;

  InputComponent confirmInput;
  TextEditingController confirmController;

  bool _isPasswordValid = false;

  @override
  void initState() {
    passwordInput = new InputComponent(hintText: 'New password');
    passwordController = passwordInput.controller;

    confirmInput = new InputComponent(hintText: 'Confirm new password');
    confirmController = confirmInput.controller;

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
              'RESET PASSWORD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: passwordInput,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
              child: confirmInput,
            ),
            RawMaterialButton(
              onPressed: () async {
                String password = passwordController.text.trim();
                _isPasswordValid = validator.validatePassword(password);

                String confirmPassword = confirmController.text.trim();

                if (password != confirmPassword) {
                  return showAlert(context, 'Passwords must match.');
                } else if (password.length < 6 || password.length > 40) {
                  return showAlert(context, 'Password must be between 6-40 characters.');
                } else if (!_isPasswordValid) {
                  return showAlert(context, 'Password contains invalid characters.');
                }

                var response = await accountMethods.resetPassword(widget.userId, widget.token, password);
                showAlert(context, response['msg'], response['success']);
              },
              constraints: BoxConstraints(),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              fillColor: Theme.of(context).buttonColor,
              elevation: 0.0,
              child: Text(
                'Submit',
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



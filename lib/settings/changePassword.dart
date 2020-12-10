import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:email_validator/email_validator.dart';
import 'package:juneau/common/methods/validator.dart';

import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/alertComponent.dart';

class ChangePasswordModal extends StatefulWidget {
  final user;

  ChangePasswordModal({Key key, @required this.user}) : super(key: key);

  @override
  _ChangePasswordModalState createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  var user;
  BuildContext changePasswordContext;

  InputComponent currentPasswordInput;
  TextEditingController currentPasswordController;

  InputComponent newPasswordInput;
  TextEditingController newPasswordController;

  InputComponent confirmPasswordInput;
  TextEditingController confirmPasswordController;

  bool _isNewPasswordValid = false;

  Future updatePassword(passwordInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/account/' + userId + '/password';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode(passwordInfo);
    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      showAlert(changePasswordContext, 'Successfully changed password', true);
      return true;
    } else {
      var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
      if (msg == null) {
        msg = 'Something went wrong, please try again';
      }
      showAlert(changePasswordContext, msg);
      return false;
    }
  }

  @override
  void initState() {
    user = widget.user;

    currentPasswordInput = new InputComponent(hintText: 'Current Password', obscureText: true);
    currentPasswordController = currentPasswordInput.controller;

    newPasswordInput = new InputComponent(hintText: 'New Password', obscureText: true);
    newPasswordController = newPasswordInput.controller;

    confirmPasswordInput = new InputComponent(hintText: 'Confirm Password', obscureText: true);
    confirmPasswordController = confirmPasswordInput.controller;

    super.initState();
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    changePasswordContext = context;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80.0,
        backgroundColor: Theme.of(context).backgroundColor,
        brightness: Theme.of(context).brightness,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 25.0,
              color: Theme.of(context).buttonColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURRENT PASSWORD',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            currentPasswordInput,
            SizedBox(height: 18),

            Text(
              'NEW PASSWORD',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            newPasswordInput,
            SizedBox(height: 18),

            Text(
              'CONFIRM PASSWORD',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            confirmPasswordInput,
            SizedBox(height: 18),


            RawMaterialButton(
              onPressed: () async {
                if (user == null) {
                  return;
                }

                String currentPassword = currentPasswordController.text.trim();
                String newPassword = newPasswordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                _isNewPasswordValid = validator.validatePassword(newPassword);

                if (currentPassword == '') {
                  return showAlert(context, 'Provide current password.');
                }

                if (newPassword == '') {
                  return showAlert(context, 'Provide new password.');
                }

                if (confirmPassword == '') {
                  return showAlert(context, 'Provide confirm password.');
                }

                if (currentPassword == newPassword) {
                  return showAlert(context, 'New password and current password must be different.');
                }

                if (newPassword.length < 6) {
                  return showAlert(context, 'Password must be at least 6 characters.');
                } else if (!_isNewPasswordValid) {
                  return showAlert(context, 'Password contains invalid characters.');
                }

                if (newPassword != confirmPassword) {
                  return showAlert(context, 'Confirm password must match new password.');
                }

                var passwordInfo = {
                  'currentPassword': currentPassword,
                  'newPassword': newPassword,
                };

                bool updated = await updatePassword(passwordInfo);
                if (updated) {
                  Navigator.pop(context);
                }
              },
              constraints: BoxConstraints(),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              fillColor: Theme.of(context).buttonColor,
              elevation: 0.0,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Theme.of(context).backgroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).backgroundColor,
                  width: 1,
                  style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      ));
  }
}

import 'package:flutter/material.dart';

import 'package:email_validator/email_validator.dart';
import 'package:juneau/common/methods/validator.dart';

import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/alertComponent.dart';

class EditProfileModal extends StatefulWidget {
  final user;

  EditProfileModal({
    Key key,
    @required this.user
  }) : super(key: key);

  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  var user;

  InputComponent usernameInput;
  TextEditingController usernameController;

  InputComponent emailInput;
  TextEditingController emailController;

  bool _isEmailValid = false;
  bool _isUsernameValid = false;

  @override
  void initState() {
    user = widget.user;

    usernameInput = new InputComponent(hintText: 'Username');
    usernameController = usernameInput.controller;
    usernameController.text = user['username'];

    emailInput = new InputComponent(hintText: 'Email');
    emailController = emailInput.controller;
    emailController.text = user['email'];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
              'Username',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            usernameInput,
            SizedBox(height: 15),
            Text(
              'Email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            emailInput,
            SizedBox(height: 15),
            RawMaterialButton(
              onPressed: () {
                String username = usernameController.text.trim();
                String email = emailController.text.trim();


                var updatedInfo = {};

                if (username != '' && username != user['username']) {

                  _isUsernameValid = validator.validateUsername(username);

                  if (!_isUsernameValid) {
                    return showAlert(context, 'Username contains invalid characters.');
                  }

                  updatedInfo['username'] = username;
                }

                if (email != '' && email != user['email']) {
                  _isEmailValid = EmailValidator.validate(email);

                  if (!_isEmailValid) {
                    return showAlert(context, 'Invalid email address.');
                  }

                  updatedInfo['email'] = email;
                }

                print(updatedInfo);
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
                  style: BorderStyle.solid
                ),
                borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      )
    );
  }
}

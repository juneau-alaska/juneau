import 'package:flutter/material.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/accountMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/methods/validator.dart';

class ResetPasswordPage extends StatefulWidget {
  final userId;

  ResetPasswordPage({
    Key key,
    @required this.userId,
  }) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  InputComponent passwordInput;
  TextEditingController passwordController;

  InputComponent confirmInput;
  TextEditingController confirmController;

  TextEditingController numController1 = TextEditingController();
  TextEditingController numController2 = TextEditingController();
  TextEditingController numController3 = TextEditingController();
  TextEditingController numController4 = TextEditingController();
  TextEditingController numController5 = TextEditingController();
  TextEditingController numController6 = TextEditingController();

  bool _isPasswordValid = false;
  bool _isCodeView = true;

  @override
  void initState() {
    passwordInput = new InputComponent(hintText: 'New password', obscureText: true);
    passwordController = passwordInput.controller;

    confirmInput = new InputComponent(hintText: 'Confirm new password', obscureText: true);
    confirmController = confirmInput.controller;

    super.initState();
  }

  @override
  void dispose() {
    numController1.dispose();
    numController2.dispose();
    numController3.dispose();
    numController4.dispose();
    numController5.dispose();
    numController6.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool isNum(String string) {
    final numericRegex =
    RegExp(r'^[0-9]+$');

    return numericRegex.hasMatch(string);
  }

  @override
  Widget build(BuildContext context) {

    UnderlineInputBorder borderOutline = UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor, width: 0.5));

    final node = FocusScope.of(context);

    void resetCode() {
      numController1.text = '';
      numController2.text = '';
      numController3.text = '';
      numController4.text = '';
      numController5.text = '';
      numController6.text = '';

      node.requestFocus(node.children.first);
    }

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
      body: _isCodeView
        ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ENTER CODE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) {
                            if (!isNum(s)) {
                              return numController1.text = '';
                            }

                            if (s != '') {
                              node.nextFocus();
                              if (numController2.text != '') {
                                numController2.selection = TextSelection(baseOffset: 0, extentOffset: 1);
                              }
                            }
                          },
                          maxLength: 1,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController1,
                          onTap: () => numController1.text != '' ? numController1.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),

                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) {
                            if (!isNum(s)) {
                              return numController2.text = '';
                            }

                            if (s != '') {
                              node.nextFocus();
                              if (numController3.text != '') {
                                numController3.selection = TextSelection(baseOffset: 0, extentOffset: 1);
                              }
                            }
                          },
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline,
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController2,
                          onTap: () => numController2.text != '' ? numController2.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),

                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) {
                            if (!isNum(s)) {
                              return numController3.text = '';
                            }

                            if (s != '') {
                              node.nextFocus();
                              if (numController4.text != '') {
                                numController4.selection = TextSelection(baseOffset: 0, extentOffset: 1);
                              }
                            }
                          },
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline,
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController3,
                          onTap: () => numController3.text != '' ? numController3.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),

                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) {
                            if (!isNum(s)) {
                              return numController4.text = '';
                            }

                            if (s != '') {
                              node.nextFocus();
                              if (numController5.text != '') {
                                numController5.selection = TextSelection(baseOffset: 0, extentOffset: 1);
                              }
                            }
                          },
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline,
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController4,
                          onTap: () => numController4.text != '' ? numController4.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),

                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) {
                            if (!isNum(s)) {
                              return numController5.text = '';
                            }

                            if (s != '') {
                              node.nextFocus();
                              if (numController6.text != '') {
                                numController6.selection = TextSelection(baseOffset: 0, extentOffset: 1);
                              }
                            }
                          },
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline,
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController5,
                          onTap: () => numController5.text != '' ? numController5.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),

                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          onChanged: (s) async {
                            if (!isNum(s)) {
                              return numController6.text = '';
                            }

                            String num1 = numController1.text;
                            String num2 = numController2.text;
                            String num3 = numController3.text;
                            String num4 = numController4.text;
                            String num5 = numController5.text;
                            String num6 = numController6.text;

                            if (
                              num1 == ''
                              || num2 == ''
                              || num3 == ''
                              || num4 == ''
                              || num5 == ''
                              || num6 == ''
                            ) {
                              resetCode();
                              return showAlert(context, 'Invalid code.');
                            }

                            String code = num1 + num2 + num3 + num4 + num5 + num6;
                            var res = await userMethods.validateCode(widget.userId, code);

                            if (res['status_code'] != 200) {
                              resetCode();
                              return showAlert(context, res['msg']);
                            }

                            setState(() {
                              _isCodeView = false;
                            });
                          },
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 40.0,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 6.0),
                            focusedBorder: borderOutline,
                            enabledBorder: borderOutline,
                          ),
                          keyboardType: TextInputType.number,
                          controller: numController6,
                          onTap: () => numController6.text != '' ? numController6.selection = TextSelection(baseOffset: 0, extentOffset: 1) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )

        // PASSWORD VIEW
        : Padding(
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
                padding: const EdgeInsets.only(top: 15.0),
                child: passwordInput,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 30.0),
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

                  var response = await accountMethods.resetPassword(widget.userId, password);
                  bool success = response['success'];
                  showAlert(context, response['msg'], success);

                  if (success) {
                    // TODO: LOGIN
                  }
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



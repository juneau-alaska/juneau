import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'package:juneau/common/components/alertComponent.dart';

class AccountMethods {

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

  Future updatePassword(passwordInfo, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = API_URL + 'account/' + userId + '/password';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode(passwordInfo);
    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      showAlert(context, 'Successfully changed password', true);
      return true;
    } else {
      var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
      if (msg == null) {
        msg = 'Something went wrong, please try again';
      }
      showAlert(context, msg);
      return false;
    }
  }

  Future resetPassword(String userId, String password) async {
    String url = API_URL + 'account/reset_password';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    var body = jsonEncode({
      'userId': userId,
      'password': password,
    });

    var response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    var jsonResponse = jsonDecode(response.body);
    bool success = response.statusCode == 200;

    return {
      'msg': jsonResponse['message'],
      'success': success,
    };
  }
}

AccountMethods accountMethods = new AccountMethods();

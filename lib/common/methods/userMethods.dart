import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UserMethods {
  Future getUser(String userId) async {
    var url = 'http://localhost:4000/user/' + userId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  Future lookUpUsers(String partial) async {
    var url = 'http://localhost:4000/users';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var body = jsonEncode({'partialText': partial});

    var response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  Future updateUser(Object user) async {
    print(user);
  }
}

UserMethods userMethods = new UserMethods();

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserMethods {
  Future getUser(String userId) async {
    String url = API_URL + 'user/' + userId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

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

  Future getUserByEmail(String email) async {
    String url = API_URL + 'user/email/' + email;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

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

  Future getUserByUsername(String username) async {
    String url = API_URL + 'user/username/' + username;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

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

  Future searchUsers(String partial) async {
    String url = API_URL + 'users';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

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
      return [];
    }
  }

  Future updateUser(String userId, attrs) async {
    String url = API_URL + 'user/' + userId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode(attrs);

    var response = await http.put(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body),
          user = jsonResponse['user'];

      return user;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  Future followUser(String username, bool unfollow, List followingUsers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');
    var jsonResponse, user;

    String url = API_URL + 'user/' + userId;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    },
      response,
      body;

    response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      jsonResponse = jsonDecode(response.body);

      user = jsonResponse;
      followingUsers = user['followingUsers'];

      if (!followingUsers.contains(username) || unfollow) {
        if (unfollow) {
          followingUsers.remove(username);
        } else {
          followingUsers.add(username);
        }

        body = jsonEncode({'followingUsers': followingUsers});
        response = await http.put(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          jsonResponse = jsonDecode(response.body);

          return jsonResponse['user'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  void resetPassword(String email) async {
    String url = API_URL + 'user/reset-password';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    var body = jsonEncode({'email': email});

    await http.post(
      url,
      headers: headers,
      body: body,
    );
  }
}

UserMethods userMethods = new UserMethods();

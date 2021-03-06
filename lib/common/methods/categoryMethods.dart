import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryMethods {
  Future searchCategories(String partial) async {
    String url = API_URL + 'categories';

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

  Future categoryAddFollower(String category, bool unfollow) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = API_URL + 'category/followers';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'name': category, 'userId': userId, 'unfollow': unfollow});
    await http.put(url, headers: headers, body: body);
  }

  Future followCategory(String category, bool unfollow, List followingCategories) async {
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
      followingCategories = user['followingCategories'];

      if (!followingCategories.contains(category) || unfollow) {
        if (unfollow) {
          followingCategories.remove(category);
        } else {
          followingCategories.add(category);
        }

        body = jsonEncode({'followingCategories': followingCategories});
        response = await http.put(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          jsonResponse = jsonDecode(response.body);

          await categoryAddFollower(category, unfollow);

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
}

CategoryMethods categoryMethods = new CategoryMethods();

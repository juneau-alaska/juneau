import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PollMethods {
  Future<List> getPollsFromUser(String userId, {String prevId}) async {
    String url = API_URL + 'polls';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'prevId': prevId, 'createdBy': userId});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      // TODO: FIX
      // if (jsonResponse.length > 0) {
      //   prevId = jsonResponse.last['_id'];
      // }

      return jsonResponse;
    } else {
      return [];
    }
  }

  Future<List> getPollsFromCategory(String category, {String prevId}) async {
    String url = API_URL + 'polls';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'prevId': prevId, 'categories': [category]});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      // TODO: FIX
      // if (jsonResponse.length > 0) {
      //   prevId = jsonResponse.last['_id'];
      // }

      return jsonResponse;
    } else {
      return [];
    }
  }

  Future getPoll(String pollId) async {
    String url = API_URL + 'poll/' + pollId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } else {
      return null;
    }
  }
}

PollMethods pollMethods = new PollMethods();

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationMethods {
  Future<List> getNotifications(String userId) async {
    String url = API_URL + 'user/' + userId + '/notifications';

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

    var jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return jsonResponse['notifications'];
    } else {
      print(jsonResponse['message']);
      return [];
    }
  }

  void createNotification(String sender, String receiver, String message, {String pollId, String commentId}) async {
    String url = API_URL + 'notification';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({
      'sender': sender,
      'receiver': [receiver],
      'message': message,
      'pollId': pollId,
      'commentId': commentId,
    });

    await http.post(url, headers: headers, body: body);
  }

  void markManyAsRead(List ids, user) async {
    String url = API_URL + 'notifications';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({
      'ids': ids,
      'readerId': user['_id'],
    });

    await http.post(url, headers: headers, body: body);
  }
}

NotificationMethods notificationMethods = new NotificationMethods();

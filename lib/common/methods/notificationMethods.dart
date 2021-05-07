import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationMethods {

  void createNotification(sender, receiver, message, redirect) async {
    String url = API_URL + 'notification';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({
      'sender': sender,
      'receiver': receiver,
      'message': message,
      'redirect': redirect,
    });

    await http.post(url, headers: headers, body: body);
  }
}

NotificationMethods notificationMethods = new NotificationMethods();

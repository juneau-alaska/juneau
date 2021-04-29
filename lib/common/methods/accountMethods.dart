import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';

class AccountMethods {

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

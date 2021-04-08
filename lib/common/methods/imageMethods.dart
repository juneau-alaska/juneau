import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageMethods {
  Future getImage(String url) async {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  }

  Future getImageUrl(String fileType) async {
    String url = API_URL + 'image/create_url';
    print(url);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body, response;

    body = jsonEncode({'fileType': fileType});

    response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<void> uploadFile(String url, Asset asset) async {
    try {
      ByteData byteData = await asset.getThumbByteData(600, 600, quality: 80);
      var response = await http.put(url, body: byteData.buffer.asUint8List());
      if (response.statusCode == 200) {
        print('Successfully uploaded photo');
      }
    } catch (e) {
      throw ('Error uploading photo');
    }
  }

  Future deleteFile(String imgUrl) async {
    String url = API_URL + 'image/delete';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    List keys = [];

    var split = imgUrl.split('/'),
        key = split[split.length - 1];

    keys.add({
      'Key': key
    });

    var body = jsonEncode({'keys': keys});
    await http.post(url, headers: headers, body: body);
  }

  Future deleteFiles(List keys) async {
    String url = API_URL + 'image/delete';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'keys': keys});
    await http.post(url, headers: headers, body: body);
  }
}

ImageMethods imageMethods = new ImageMethods();

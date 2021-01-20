import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageMethods {
  Future getImageUrl(String fileType) async {
    const url = 'http://localhost:4000/image/create_url';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body, response;

    body = jsonEncode({'fileType': fileType, 'bucket': 'poll-option'});

    response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<void> uploadFile(String url, Asset asset) async {
    try {
      ByteData byteData = await asset.getByteData(quality: 1);
      var response = await http.put(url, body: byteData.buffer.asUint8List());
      if (response.statusCode == 200) {
        print('Successfully uploaded photo');
      }
    } catch (e) {
      throw ('Error uploading photo');
    }
  }

  Future deleteFile(String imgUrl, String bucket) async {
    String url = 'http://localhost:4000/image/delete';

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

    var body = jsonEncode({'keys': keys, 'bucket': bucket});
    await http.post(url, headers: headers, body: body);
  }

  Future deleteFiles(List keys, String bucket) async {
    String url = 'http://localhost:4000/image/delete';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'keys': keys, 'bucket': bucket});
    await http.post(url, headers: headers, body: body);
  }
}

ImageMethods imageMethods = new ImageMethods();

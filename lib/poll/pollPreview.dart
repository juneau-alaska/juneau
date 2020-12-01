import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PollPreview extends StatefulWidget {
  final pollObject;

  PollPreview({
    Key key,
    @required this.pollObject,
  }) : super(key: key);

  @override
  _PollPreviewState createState() => _PollPreviewState();
}

class _PollPreviewState extends State<PollPreview> {
  var poll;
  List options;
  List images;
  Widget preview;

  Future<List<int>> getImageBytes(option) async {
    String url = option['content'];
    List<int> imageBytes;

    var response = await http.get(url);
    if (response.statusCode == 200) {
      imageBytes = response.bodyBytes;
    }

    return imageBytes;
  }

  Future<List> getOptions(poll) async {
    const url = 'http://localhost:4000/option';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    List optionIds = poll['options'];
    List<Future> futures = [];
    List options;

    for (int i = 0; i < optionIds.length; i++) {
      var optionId = optionIds[i];
      Future future() async {
        var response = await http.get(
          url + '/' + optionId,
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

      futures.add(future());
    }

    await Future.wait(futures).then((results) {
      options = results;
    });

    return options;
  }

  Future<Widget> buildPreview(size) async {
      poll =  widget.pollObject['poll'];

      if (preview == null) {

        options = await getOptions(poll);
        widget.pollObject['options'] = options;

        List images = [];

        var firstOption = options[0];
        int highestIndex = 0;
        int highestVoteCount = firstOption['votes'];

        for (int i = 1; i < options.length; i++) {
          var option = options[i];
          int votes = option['votes'];

          if (votes > highestVoteCount) {
            highestVoteCount = votes;
            highestIndex = i;
          }

          List<int> image = await getImageBytes(option);
          images.add(image);
        }

        widget.pollObject['images'] = images;
        preview = Container(
          width: size,
          height: size,
          child: Image.memory(
            images[highestIndex],
            fit: BoxFit.cover,
            width: size,
          ),
        );
      }

      return preview;
  }

  @override
  Widget build(BuildContext context) {
    double size = (MediaQuery.of(context).size.width / 3) - 2;

    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(0.5),
        child: FutureBuilder<Widget>(
          future: buildPreview(size),
          builder: (context, AsyncSnapshot<Widget> pollPreview) {
            if (pollPreview.hasData) {
              return Container(
                color: Theme.of(context).hintColor,
                child: pollPreview.data
              );
            } else {
              return Container(
                width: size,
                height: size,
                color: Theme.of(context).hintColor,
              );
            }
          }
        ),
      ),
    );
  }
}

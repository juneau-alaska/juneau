import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PollPreview extends StatefulWidget {
  final poll;

  PollPreview({
    Key key,
    @required this.poll,
  }) : super(key: key);

  @override
  _PollPreviewState createState() => _PollPreviewState();
}

class _PollPreviewState extends State<PollPreview> {
  List options;
  Widget pollPreview;

  Future<Widget> getImage(option) async {
    String url = option['content'];
    List<int> imageBytes;

    var response = await http.get(url);
    if (response.statusCode == 200) {
      imageBytes = response.bodyBytes;
    }

    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
      width: MediaQuery.of(context).size.width / 3,
    );
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

    for (var i = 0; i < optionIds.length; i++) {
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

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      options = await getOptions(widget.poll);

      if (options != null && options.length > 0) {
        var firstOption = options[0];
        var highestVotedOption = firstOption;
        int highestVoteCount = firstOption['votes'];

        for (var i = 1; i < options.length; i++) {
          var option = options[i];
          int votes = option['votes'];

          if (votes > highestVoteCount) {
            highestVoteCount = votes;
            highestVotedOption = option;
          }
        }

        pollPreview = await getImage(highestVotedOption);
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return pollPreview != null
        ? pollPreview
        : Container(
            color: Theme.of(context).hintColor,
          );
  }
}

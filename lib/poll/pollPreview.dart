import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PollPreview extends StatefulWidget {
  final pollObject;
  final openListView;

  PollPreview({
    Key key,
    @required this.pollObject,
    this.openListView,
  }) : super(key: key);

  @override
  _PollPreviewState createState() => _PollPreviewState();
}

class _PollPreviewState extends State<PollPreview> {
  var pollObject;
  var poll;
  List options;
  List images;
  Widget preview;
  int index;

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
    options = await getOptions(poll);
    pollObject['options'] = options;

    List images = [];

    for (int i = 0; i < options.length; i++) {
      var option = options[i];
      List<int> image = await getImageBytes(option);
      images.add(image);
    }

    pollObject['images'] = images;
    preview = Container(
      width: size,
      height: size,
      child: Image.memory(
        images[0],
        fit: BoxFit.cover,
        width: size,
      ),
    );

    pollObject['preview'] = preview;
    return preview;
  }

  @override
  void initState() {
    pollObject = widget.pollObject;
    poll = pollObject['poll'];
    preview = pollObject['preview'];
    index = pollObject['index'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double size = (MediaQuery.of(context).size.width / 3) - 0.5;

    return GestureDetector(
      onTap: () {
        widget.openListView(index, poll['_id']);
      },
      child: Padding(
        padding: const EdgeInsets.all(0.25),
        child: preview == null
            ? FutureBuilder<Widget>(
                future: buildPreview(size),
                builder: (context, AsyncSnapshot<Widget> pollPreview) {
                  if (pollPreview.hasData) {
                    return Container(color: Theme.of(context).hintColor, child: pollPreview.data);
                  } else {
                    return Container(
                      width: size,
                      height: size,
                      color: Theme.of(context).hintColor,
                    );
                  }
                })
            : preview,
      ),
    );
  }
}

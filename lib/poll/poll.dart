import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:juneau/common/methods/userMethods.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<List> _getImages(List options) async {
  List imageBytes = [];
  for (var option in options) {
    String url = option['content'];
    var response = await http.get(url);
    if (response.statusCode == 200) {
      imageBytes.add(response.bodyBytes);
    }
  }
  return imageBytes;
}

Future<List> _getOptions(poll) async {
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

class PollWidget extends StatefulWidget {
  final poll;
  final user;

  PollWidget({Key key, @required this.poll, this.user}) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var pollCreator, options;

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    userMethods.getUser(widget.poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(widget.poll).then((pollOptions) {
        if (mounted) {
          setState(() {
            if (pollOptions != null && pollOptions.length > 0) {
              options = pollOptions;
            }
          });
        }
      });
    });
  }

  void vote(option) async {
    var poll = widget.poll,
        url = 'http://localhost:4000/option/vote/' + option['_id'];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.put(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body),
          updateOption = jsonResponse['option'];

      for (var i = 0; i < options.length; i++) {
        if (options[i]['_id'] == updateOption["_id"]) {
          options[i] = updateOption;
          break;
        }
      }

      updateUserCompletedPolls(poll['_id'], option['_id']);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void updateUserCompletedPolls(pollId, optionId) async {
    const url = 'http://localhost:4000/user/';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token'), userId = prefs.getString('userId');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url + userId, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body)[0],
          completedPolls = jsonResponse['completedPolls'],
          selectedOptions = jsonResponse['selectedOptions'];

      completedPolls.add(pollId);
      selectedOptions.add(optionId);

      var body = jsonEncode({
        'completedPolls': completedPolls,
        'selectedOptions': selectedOptions
      });

      response = await http.put(url + userId, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body),
            user = jsonResponse['user'];

        if (mounted) {
          setState(() {
            widget.user[0] = user;
          });
        }
      }
      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Widget buildPoll() {
    var createdAt = DateTime.parse(widget.poll['createdAt']),
        time = timeago.format(createdAt, locale: 'en_short');

    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.only(
            left: 10.0, right: 10.0, top: 3.0, bottom: 3.0),
        child: Text(
          widget.poll['prompt'],
          style: TextStyle(
            fontFamily: 'Lato Black',
            fontSize: 20.0,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 3.0),
        child: Row(
          children: <Widget>[
            GestureDetector(
                child: Text(
                  pollCreator['username'],
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14.0,
                  ),
                ),
                onTap: () {
                  print(pollCreator['email']);
                }),
            Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 2.0),
              child: Text(
                time,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  wordSpacing: -4.0,
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    if (options.length > 0) {
      var poll = widget.poll,
          user = widget.user[0],
          selectedOptions = user['selectedOptions'],
          completedPolls = user['completedPolls'];

      bool completed = completedPolls.indexOf(poll['_id']) >= 0;
      int totalVotes = 0;

      if (completed) {
        for (var c in options) {
          totalVotes += c['votes'];
        }
      }

      children.add(FutureBuilder<List>(
          future: _getImages(options),
          builder: (context, AsyncSnapshot<List> imageBytes) {
            if (imageBytes.hasData) {
              List imageBytesList = imageBytes.data;
              int imageBytesListLength = imageBytesList.length;

              double containerHeight;
              if (imageBytesListLength == 2) {
                containerHeight = 200;
              } else if (imageBytesListLength <= 4) {
                containerHeight = 400;
              } else if (imageBytesListLength <= 6) {
                containerHeight = 300;
              } else if (imageBytesListLength <= 9) {
                containerHeight = 400;
              }

              int highestVote = 0;
              int highestIndex = 0;

              for (var i = 0; i < options.length; i++) {
                var option = options[i];
                int votes = option['votes'];
                if (votes > highestVote) {
                  highestVote = votes;
                  highestIndex = i;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  height: containerHeight,
                  child: GridView.count(
                      physics: new NeverScrollableScrollPhysics(),
                      crossAxisCount: imageBytesListLength > 4 ? 3 : 2,
                      children: List.generate(imageBytesListLength, (index) {
                        var option = options[index];
                        int votes = option['votes'];
                        double percent = votes > 0 ? votes / totalVotes : 0;
                        String percentStr =
                            (percent * 100.0).toStringAsFixed(0) + '%';

                        Image image = Image.memory(imageBytesList[index]);

                        return Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (!completed) {
                                HapticFeedback.mediumImpact();
                                vote(options[index]);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  child: image,
                                  width: imageBytesListLength > 4 ? 300 : 600,
                                  height: imageBytesListLength > 4 ? 300 : 600,
                                ),
                                completed
                                    ? Stack(children: [
                                        Opacity(
                                          opacity: 0.5,
                                          child: Container(
                                            decoration: new BoxDecoration(
                                              color: Theme.of(context)
                                                  .highlightColor,
                                            ),
                                            width: imageBytesListLength > 4
                                                ? 300
                                                : 600,
                                            height: imageBytesListLength > 4
                                                ? 300
                                                : 600,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            percentStr,
                                            style: TextStyle(
                                                fontSize:
                                                    imageBytesListLength > 4
                                                        ? 15.0
                                                        : 16.5,
                                                fontWeight: FontWeight.w600,
                                                color: highestIndex == index
                                                    ? Colors.red
                                                    : Colors.white),
                                          ),
                                        ),
                                        selectedOptions
                                                    .indexOf(option['_id']) >=
                                                0
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 2.5,
                                                            right: 3.0),
                                                    child: Opacity(
                                                      opacity: 0.7,
                                                      child: new Icon(
                                                        Icons.check_circle,
                                                        size: 20.0,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : new SizedBox(
                                                width: 0.0, height: 0.0),
                                      ])
                                    : Container(),
                              ],
                            ),
                          ),
                        );
                      })),
                ),
              );
            } else {
              return new Container(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
          }));

      // TODO: Temporary Bottom Padding
      children.add(SizedBox(height: 60.0));
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  void initState() {
    userMethods.getUser(widget.poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(widget.poll).then((pollOptions) {
        if (mounted) {
          setState(() {
            if (pollOptions != null && pollOptions.length > 0) {
              options = pollOptions;
            }
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (options == null) {
      return new Container();
    }
    return buildPoll();
  }
}

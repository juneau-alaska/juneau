import 'dart:typed_data';

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
        HttpHeaders.contentTypeHeader : 'application/json',
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

    await Future.wait(futures)
        .then((results) {
        options = results;
    });

    return options;
}

class PollWidget extends StatefulWidget {
    final poll;
    var user;

    PollWidget({ Key key, @required this.poll, this.user}) : super(key: key);

    @override
    _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
    var pollCreator, options;

    void vote(option) async {
        var poll = widget.poll,
            url = 'http://localhost:4000/option/vote/' + option['_id'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        var token = prefs.getString('token');

        var headers = {
            HttpHeaders.contentTypeHeader : 'application/json',
            HttpHeaders.authorizationHeader: token
        };

        var response = await http.put(
            url,
            headers: headers
        );

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
        var token = prefs.getString('token'),
            userId = prefs.getString('userId');

        var headers = {
            HttpHeaders.contentTypeHeader : 'application/json',
            HttpHeaders.authorizationHeader: token
        };

        var response = await http.get(
            url + userId,
            headers: headers
        );

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

            response = await http.put(
                url + userId,
                headers: headers,
                body: body
            );

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
            time = timeago.format(createdAt, locale: 'en_short'),
            borderRadiusValue = 8.0;

        List<Widget> children = [
            SizedBox(
                height: 10.0
            ),
            Text(
                widget.poll['prompt'],
                style: TextStyle(
                    fontFamily: 'Lato Black',
                    fontSize: 20.0,
                ),
            ),
            SizedBox(
                height: 2.8
            ),
            Row(
                children: <Widget>[
                    GestureDetector(
                        child: Text(
                            pollCreator['username'],
                            style: TextStyle(
                                color: Theme.of(context).buttonColor,
                                fontSize: 14.0,
                            ),
                        ),
                        onTap: () {
                            print(pollCreator['email']);
                        }
                    ),
                    SizedBox(
                        width: 1.0,
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 2.0),
                        child: Text(
                            time,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12.5,
                                wordSpacing: -3.0,
                            ),
                        ),
                    ),
                ],
            ),
            SizedBox(
                height: 8.0
            ),
        ];

        if (options.length > 0) {
            var poll = widget.poll,
                user = widget.user[0],
                selectedOptions = user['selectedOptions'],
                completedPolls = user['completedPolls'];

            bool completed = completedPolls.indexOf(poll['_id']) >= 0;
            int totalVotes = 0;
            String type = options[0]['contentType'];

            if (completed) {
                for (var c in options) {
                    totalVotes += c['votes'];
                }
            }

            if (type == "text") {
                for (var option in options) {
                    String percentStr = "";
                    Widget resultBar = new Container();

                    double borderRadius = borderRadiusValue;
                    int charLimit = 30;
                    int stringLength = option['content'].length < charLimit ? 0 : option['content'].length;
                    double optionHeight = 40.0 + 10*(stringLength/charLimit);

                    if (completed) {
                        int votes = option['votes'];
                        double percent = votes > 0 ? votes/totalVotes : 0;
                        BorderRadius radius = BorderRadius.circular(borderRadius);

                        if (percent < 1.0) {
                            radius = BorderRadius.only(topLeft: Radius.circular(borderRadius), bottomLeft: Radius.circular(borderRadius));
                        }

                        if (percent > 0) {
                            percentStr = (percent * 100.0).toStringAsFixed(0) + '%';
                        }

                        Color resultColor = Theme.of(context).highlightColor;
                        LinearGradient lineGradient;

                        if (selectedOptions.indexOf(option['_id']) >= 0 ) {
                            resultColor = Colors.white;
                            lineGradient = LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [const Color(0xff58E0C0), const Color(0xFF5a58dd)],
                                tileMode: TileMode.repeated,
                            );
                        }

                        resultBar = new Container(
                            height: optionHeight + 1,
                            width: MediaQuery.of(context).size.width * percent,
                            decoration: new BoxDecoration(
                                color: resultColor,
                                gradient: lineGradient,
                                borderRadius: radius,
                                border: Border.all(
                                    color: Colors.transparent,
                                    width: 0.75,
                                ),
                            ),
                        );
                    }

                    children.add(
                        Stack(
                            children: <Widget>[
                                new Container(
                                    height: optionHeight + 1,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: new BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(borderRadiusValue),
                                        border: Border.all(
                                            color: Colors.transparent,
                                            width: 0.75,
                                        ),
                                    ),
                                ),
                                resultBar,
                                GestureDetector(
                                    onDoubleTap: () {
                                        if (!completed) {
                                            HapticFeedback.mediumImpact();
                                            vote(option);
                                        }
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(bottom: 7.5),
                                        decoration: new BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(borderRadius),
                                            border: Border.all(
                                                color: Colors.transparent,
                                                width: 0.75,
                                            ),
                                        ),
                                        child: Row(
                                            children: <Widget>[
                                                new Flexible(
                                                    child: new Column(
                                                        children: <Widget>[
                                                            Center(
                                                                child: Container(
                                                                    height: optionHeight,
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.only(left: 10.0, right: 15.0),
                                                                        child: Align(
                                                                            alignment: Alignment.centerLeft,
                                                                            child: Text(
                                                                                option['content'],
                                                                                style: TextStyle(
                                                                                    fontSize: 16.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                ),
                                                                            ),
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.only(right: 8.0),
                                                    child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: <Widget>[
                                                            Text(
                                                                "$percentStr ",
                                                                style: TextStyle(
                                                                    fontSize: 14.0,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            ],
                        )
                    );
                }
            } else {
                children.add(
                    FutureBuilder<List>(
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
                                    containerHeight = 250;
                                } else if (imageBytesListLength <= 9) {
                                    containerHeight = 375;
                                }

                                return Container(
                                    height: containerHeight,
                                    child: GridView.count(
                                        physics: new NeverScrollableScrollPhysics(),
                                        crossAxisCount: imageBytesListLength > 4 ? 3 : 2,
                                        children: List.generate(imageBytesListLength, (index) {
                                            Image image = Image.memory(imageBytesList[index]);
                                            return Padding(
                                                padding: const EdgeInsets.all(2.0),
                                                child : Container(
                                                    child: image,
                                                    width: imageBytesListLength > 4 ? 300 : 600,
                                                    height: imageBytesListLength > 4 ? 300 : 600,
                                                ),
                                            );
                                        })
                                    ),
                                );
                            } else {
                                return new Container(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator()
                                    ),
                                );
                            }
                        }
                    )
                );
            }
        }

//    children.add(
//      Row(
//        children: <Widget>[
//          Icon(
//            Icons.favorite,
//            color: Colors.redAccent,
//            size: 20.0,
//          ),
//          Icon(
//            Icons.mode_comment,
//            size: 20.0,
//          ),
//        ],
//      )
//    );

        return Container(
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                ),
            ),
        );
    }

    @override
    void initState() {
        userMethods.getUser(widget.poll['createdBy'])
            .then((pollUser) {
            if (pollUser != null && pollUser.length > 0) {
                pollCreator = pollUser[0];
            }
            _getOptions(widget.poll)
                .then((pollOptions) {
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


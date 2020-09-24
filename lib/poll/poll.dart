import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/poll/pollMenu.dart';
import 'package:juneau/common/components/alertComponent.dart';

import 'package:juneau/common/methods/userMethods.dart';

Future<List> getImages(List options) async {
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

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

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
  final dismissPoll;
  final index;
  final updatedUserModel;
  final parentController;

  PollWidget({Key key, @required this.poll, this.user, this.dismissPoll, this.index, this.updatedUserModel, this.parentController}) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var user, poll, pollCreator;

  List options;
  List followingCategories;
  Widget imageOptions;

  final streamController = StreamController();
  bool warning = false;

  @override
  void initState() {
    poll = widget.poll;
    user = widget.user;

    followingCategories = user['followingCategories'];

    userMethods.getUser(poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(poll).then((pollOptions) {
        if (mounted) {
          setState(() {
            if (pollOptions != null && pollOptions.length > 0) {
              options = pollOptions;
            }
          });
        }
      });
    });

    streamController.stream.throttleTime(Duration(milliseconds: 1000)).listen((category) {
      bool unfollow = false;
      if (followingCategories.contains(category)) {
        unfollow = true;
      }

      warning = true;
      Timer(Duration(milliseconds: 1000), () {
        warning = false;
      });

      followCategory(category, unfollow, context);
    });

    widget.parentController.stream.asBroadcastStream().listen((newUser) {
      if (mounted)
        setState(() {
          user = newUser;
          followingCategories = user['followingCategories'];
        });
    });

    super.initState();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  Future categoryAddFollower(String category, String userId, bool unfollow) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/category/followers';

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var body = jsonEncode({'name': category, 'userId': userId, 'unfollow': unfollow});
    await http.put(url, headers: headers, body: body);
  }

  Future followCategory(String category, bool unfollow, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/user/' + userId;

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token}, response, body;

    response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      user = jsonResponse[0];
      followingCategories = user['followingCategories'];

      if (!followingCategories.contains(category) || unfollow) {
        if (unfollow) {
          followingCategories.remove(category);
        } else {
          followingCategories.add(category);
        }

        body = jsonEncode({'followingCategories': followingCategories});
        response = await http.put(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          user = jsonResponse['user'];

          await categoryAddFollower(category, userId, unfollow);
          widget.updatedUserModel(user);
        } else {
          return showAlert(context, 'Something went wrong, please try again');
        }
      } else {
        setState(() {});
      }
    } else {
      return showAlert(context, 'Something went wrong, please try again');
    }
  }

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    userMethods.getUser(poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(poll).then((pollOptions) {
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
    String url = 'http://localhost:4000/option/vote/' + option['_id'].toString();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.put(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body), updateOption = jsonResponse['option'];

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

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.get(url + userId, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body)[0],
          completedPolls = jsonResponse['completedPolls'],
          selectedOptions = jsonResponse['selectedOptions'];

      completedPolls.add(pollId);
      selectedOptions.add(optionId);

      var body = jsonEncode({'completedPolls': completedPolls, 'selectedOptions': selectedOptions});

      response = await http.put(url + userId, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        user = jsonResponse['user'];

        if (mounted) {
          setState(() {});
        }
      }
      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void deleteOptions() async {
    String url = 'http://localhost:4000/options/delete';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var body = jsonEncode({'optionsList': options});
    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      showAlert(context, 'Successfully deleted poll', true);
      widget.dismissPoll(widget.index);
    } else {
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void deletePoll() async {
    String url = 'http://localhost:4000/poll/' + poll['_id'].toString();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      deleteOptions();
    } else {
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void handleAction(String action) {
    switch (action) {
      case 'delete':
        Widget cancelButton = FlatButton(
          child: Text(
            "CANCEL",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700
            )
          ),
          onPressed:  () {
            Navigator.pop(context);
          },
        );

        Widget continueButton = FlatButton(
          child: Text(
            "DELETE",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Colors.red
            )
          ),
          onPressed:  () {
            deletePoll();
            Navigator.pop(context);
          },
        );

        AlertDialog alertDialogue = AlertDialog(
          backgroundColor: Theme.of(context).backgroundColor,
          title: Text(
            "Are you sure?",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700
            )
          ),
          content: Text(
            "Polls that are deleted cannot be retrieved.",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w300
            )
          ),
          actions: [
            cancelButton,
            continueButton,
          ],
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alertDialogue;
          },
        );
        break;
    }
  }

  Widget buildPoll() {
    DateTime createdAt = DateTime.parse(poll['createdAt']);
    List pollCategories = poll['categories'];
    String time = timeago.format(createdAt, locale: 'en_short');
    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    poll['prompt'],
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: <Widget>[
                    GestureDetector(
                        child: Text(
                          pollCreator['username'],
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 13.0,
                          ),
                        ),
                        onTap: () {
                          print(pollCreator['email']);
                        }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text('•',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          )),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                        wordSpacing: -4.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            user['_id'] == pollCreator['_id']
                ? GestureDetector(
                    onTap: () async {
                      bool isCreator = user['_id'] == pollCreator['_id'];
                      String action = await showModalBottomSheet(
                          backgroundColor: Colors.transparent, context: context, builder: (BuildContext context) => PollMenu(isCreator: isCreator));
                      handleAction(action);
                    },
                    child: Icon(
                      Icons.more_horiz,
                      size: 20.0,
                      color: Theme.of(context).hintColor,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 12.0),
        child: SizedBox(
          height: 30.0,
          child: new ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pollCategories.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  decoration: new BoxDecoration(
                      color: followingCategories.contains(pollCategories[index]) ? Theme.of(context).accentColor : Theme.of(context).highlightColor,
                      borderRadius: new BorderRadius.all(const Radius.circular(14.0))),
                  child: GestureDetector(
                    onTap: () {
                      if (warning) {
                        showAlert(context, "You're going that too fast. Take a break.");
                      }
                      HapticFeedback.mediumImpact();
                      streamController.add(pollCategories[index]);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Center(
                        child: Text(
                          pollCategories[index],
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];

    if (options.length > 0) {
      var completedPolls = user['completedPolls'];

      bool completed = completedPolls.indexOf(poll['_id']) >= 0;
      int totalVotes = 0;
      int highestVote = 0;

      if (completed) {
        for (var c in options) {
          int votes = c['votes'];
          totalVotes += votes;
          if (votes > highestVote) {
            highestVote = votes;
          }
        }
      }

      double screenWidth = MediaQuery.of(context).size.width;
      int optionsLength = options.length;
      bool lengthGreaterThanFour = optionsLength > 4;
      double divider = lengthGreaterThanFour ? 3 : 2;
      double size = screenWidth / divider;
      double containerHeight;

      if (lengthGreaterThanFour) {
        containerHeight = optionsLength > 6 ? size * 3 : size * 2;
      } else {
        containerHeight = optionsLength > 2 ? size * 2 : size;
      }

      if (imageOptions == null) {
        imageOptions = FutureBuilder<List>(
            future: getImages(options),
            builder: (context, AsyncSnapshot<List> imageBytes) {
              if (imageBytes.hasData) {
                List imageBytesList = imageBytes.data;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.75),
                  child: Container(
                    height: containerHeight,
                    child: GridView.count(
                        physics: new NeverScrollableScrollPhysics(),
                        crossAxisCount: lengthGreaterThanFour ? 3 : 2,
                        children: List.generate(optionsLength, (index) {
                          var option = options[index];
                          int votes = option['votes'];
                          double percent = votes > 0 ? votes / totalVotes : 0;
                          String percentStr = (percent * 100.0).toStringAsFixed(0) + '%';

                          Image image = Image.memory(imageBytesList[index]);

                          return Padding(
                            padding: const EdgeInsets.all(0.75),
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
                                    width: size,
                                    height: size,
                                  ),
                                  completed
                                      ? Stack(children: [
                                          Opacity(
                                            opacity: 0.3,
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                color: Theme.of(context).backgroundColor,
                                              ),
                                              width: size,
                                              height: size,
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              percentStr,
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w700,
                                                  color: highestVote == votes ? Colors.white : Colors.white70),
                                            ),
                                          ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.75),
                  child: new Container(
                      height: containerHeight,
                      child: GridView.count(
                          physics: new NeverScrollableScrollPhysics(),
                          crossAxisCount: lengthGreaterThanFour ? 3 : 2,
                          children: List.generate(optionsLength, (index) {
                            return Padding(
                              padding: const EdgeInsets.all(0.75),
                              child: Container(width: size, height: size, color: Theme.of(context).highlightColor),
                            );
                          }))),
                );
              }
            });
      }

      children.add(imageOptions);

      children.add(Padding(
        padding: const EdgeInsets.only(left: 10.0, top: 10.0),
        child: Text(
          totalVotes == 1 ? '$totalVotes vote' : '$totalVotes votes',
          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Theme.of(context).hintColor),
        ),
      ));

      children.add(SizedBox(height: 10.0));
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
  Widget build(BuildContext context) {
    if (options == null) {
      return new Container();
    }
    return buildPoll();
  }
}

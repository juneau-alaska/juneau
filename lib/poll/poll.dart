import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';
import 'package:dots_indicator/dots_indicator.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/poll/pollMenu.dart';
import 'package:juneau/common/components/alertComponent.dart';

import 'package:juneau/common/methods/userMethods.dart';

List options;
List imageBytes = [];

Future<List> getImages(List options) async {
  if (imageBytes != null && imageBytes.length == 0) {
    for (var option in options) {
      String url = option['content'];
      print(url);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        imageBytes.add(response.bodyBytes);
      }
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

class PositionalDots extends StatefulWidget {
  final controller;
  final numImages;

  PositionalDots({Key key, @required this.controller, this.numImages}) : super(key: key);

  @override
  _PositionalDotsState createState() => _PositionalDotsState();
}

class _PositionalDotsState extends State<PositionalDots> {
  double currentPosition = 0.0;

  @override
  void initState() {
    widget.controller.addListener(() {
      setState(() {
        currentPosition = widget.controller.page;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DotsIndicator(
      dotsCount: widget.numImages,
      position: currentPosition,
      decorator: DotsDecorator(
        // color: Colors.black87,
        size: Size.square(6.0),
        activeColor: Theme.of(context).highlightColor,
        activeSize: Size.square(6.0),
        spacing: const EdgeInsets.symmetric(horizontal: 2.5),
      ),
    );
  }
}

class ImageCarousel extends StatefulWidget {
  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  @override
  Widget build(BuildContext context) {
    int optionsLength = options.length;
    double screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<List>(
        future: getImages(options),
        builder: (context, AsyncSnapshot<List> imageBytes) {
          if (imageBytes.hasData) {
            List<Widget> imageWidgets = [];
            int imageIndex = 0;

            PageController pageController = PageController();

            if (imageWidgets.length == 0) {
              List imageBytesList = imageBytes.data;

              for (var i = 0; i < imageBytesList.length; i++) {
                imageWidgets.add(Image.memory(
                  imageBytesList[i],
                  height: screenWidth,
                ));
              }
            }

            return Column(
              children: [
                Container(
                  width: screenWidth,
                  height: screenWidth,
                  child: PageView(
                    children: imageWidgets,
                    controller: pageController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: PositionalDots(
                    controller: pageController,
                    numImages: imageWidgets.length,
                  ),
                ),
              ],
            );

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (imageIndex == optionsLength - 1) {
                    imageIndex = 0;
                  } else {
                    imageIndex += 1;
                  }
                });
              },
              child: Container(
                color: Colors.white,
                child: imageWidgets[imageIndex],
              ),
            );
          } else {
            return new Container(
              decoration: BoxDecoration(
                // borderRadius: BorderRadius.all(Radius.circular(13)),
                color: Theme.of(context).hintColor,
              ),
              width: screenWidth,
              height: screenWidth,
            );
          }
        });
  }
}

class PollWidget extends StatefulWidget {
  final poll;
  final user;
  final currentCategory;
  final dismissPoll;
  final viewPoll;
  final index;
  final updatedUserModel;
  final parentController;

  PollWidget(
      {Key key,
      @required this.poll,
      this.user,
      this.currentCategory,
      this.dismissPoll,
      this.viewPoll,
      this.index,
      this.updatedUserModel,
      this.parentController})
      : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  var user, poll, pollCreator;

  List followingCategories;

  final streamController = StreamController();

  bool saved = false;
  bool liked = false;
  bool warning = false;

  @override
  void initState() {
    poll = widget.poll;
    user = widget.user;

    followingCategories = user['followingCategories'];

    userMethods.getUser(poll['createdBy']).then((pollUser) {
      if (pollUser != null) {
        pollCreator = pollUser;
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

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'name': category, 'userId': userId, 'unfollow': unfollow});
    await http.put(url, headers: headers, body: body);
  }

  Future followCategory(String category, bool unfollow, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/user/' + userId;

    var headers = {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: token
        },
        response,
        body;

    response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      user = jsonResponse;
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

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

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

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url + userId, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body),
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

  void removePollFromUser(pollId) async {
    const url = 'http://localhost:4000/user/';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token'), userId = prefs.getString('userId');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url + userId, headers: headers), body;

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body), createdPolls = jsonResponse['createdPolls'];

      print(createdPolls.length);
      createdPolls.remove(pollId);
      print(createdPolls.length);
      body = jsonEncode({'createdPolls': createdPolls});

      response = await http.put(url + userId, headers: headers, body: body);
    }
  }

  void deleteOptions() async {
    String url = 'http://localhost:4000/options/delete';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

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
    String _id = poll['_id'];
    String url = 'http://localhost:4000/poll/' + _id;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      deleteOptions();
      removePollFromUser(_id);
    } else {
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void handleAction(String action) {
    switch (action) {
      case 'delete':
        Widget cancelButton = FlatButton(
          child: Text("CANCEL", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700)),
          onPressed: () {
            Navigator.pop(context);
          },
        );

        Widget continueButton = FlatButton(
          child: Text("DELETE",
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Colors.red)),
          onPressed: () {
            deletePoll();
            Navigator.pop(context);
          },
        );

        AlertDialog alertDialogue = AlertDialog(
          backgroundColor: Theme.of(context).backgroundColor,
          title:
              Text("Are you sure?", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700)),
          content: Text("Polls that are deleted cannot be retrieved.",
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w300)),
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

  @override
  Widget build(BuildContext context) {
    if (options == null || options.length == 0 || pollCreator == null) {
      return new Container();
    }

    DateTime createdAt = DateTime.parse(poll['createdAt']);
    String pollCategory = poll['category'];
    String time = timeago.format(createdAt, locale: 'en_short');

    var completedPolls = user['completedPolls'];
    var selectedOptions = user['selectedOptions'];

    bool completed = completedPolls.indexOf(poll['_id']) >= 0;
    String selectedOption;
    int totalVotes = 0;
    int highestVote = 0;

    if (completed) {
      for (var c in options) {
        String _id = c['_id'];
        if (selectedOptions.contains(_id)) {
          selectedOption = _id;
        }
        int votes = c['votes'];
        totalVotes += votes;
        if (votes > highestVote) {
          highestVote = votes;
        }
      }
    }

    ImageCarousel imageCarousel = new ImageCarousel();

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        GestureDetector(
                            child: Text(
                              pollCreator['username'],
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                              ),
                            ),
                            onTap: () {
                              print(pollCreator['email']);
                            }),
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0, right: 1.0),
                          child: Text('•',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              )),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            wordSpacing: -3.5,
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
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) => PollMenu(isCreator: isCreator));
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
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              poll['prompt'],
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: widget.currentCategory == null
                ? const EdgeInsets.fromLTRB(12.0, 15.0, 12.0, 15.0)
                : const EdgeInsets.only(top: 15.0),
            child: widget.currentCategory == null
                ? SizedBox(
                    height: 28.0,
                    child: Row(
                      children: [
                        Container(
                          decoration: new BoxDecoration(
                              color: followingCategories.contains(pollCategory)
                                  ? Theme.of(context).accentColor
                                  : Theme.of(context).hintColor,
                              borderRadius: new BorderRadius.all(const Radius.circular(18.0))),
                          child: GestureDetector(
                            onTap: () {
                              if (warning) {
                                showAlert(context, "You're going that too fast. Take a break.");
                              }
                              HapticFeedback.mediumImpact();
                              streamController.add(pollCategory);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Center(
                                child: Text(
                                  pollCategory,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    color: Theme.of(context).backgroundColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          imageCarousel,
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalVotes ',
                      style: TextStyle(fontSize: 13.0, color: Theme.of(context).hintColor),
                    ),
                    Text(
                      totalVotes == 1 ? 'vote' : 'votes',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    widget.viewPoll(widget, poll['_id']);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        poll['comments'] != null ? poll['comments'].length.toString() + ' ' : '0 ',
                        style: TextStyle(fontSize: 13.0, color: Theme.of(context).hintColor),
                      ),
                      Text(
                        poll['comments'].length == 1 ? 'comment' : 'comments',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

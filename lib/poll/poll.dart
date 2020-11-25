import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/poll/pollMenu.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/methods/numMethods.dart';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';

class PositionalDots extends StatefulWidget {
  final pageController;
  final numImages;
  final totalVotes;
  final options;
  final selectedOption;

  PositionalDots(
      {Key key,
      @required this.pageController,
      this.numImages,
      this.totalVotes,
      this.options,
      this.selectedOption})
      : super(key: key);

  @override
  _PositionalDotsState createState() => _PositionalDotsState();
}

class _PositionalDotsState extends State<PositionalDots> {
  double currentPosition = 0.0;
  int votes;
  String votePercent;
  bool selected = false;
  List options;

  @override
  void initState() {
    options = widget.options;
    currentPosition = 0;

    widget.pageController.addListener(() {
      setState(() {
        double page = widget.pageController.page;
        currentPosition = page;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int index = currentPosition.toInt();
    votes = options[index]['votes'];
    if (votes == 0) {
      votePercent = '0';
    } else {
      votePercent = (100 * votes ~/ widget.totalVotes).toString();
    }

    selected = widget.selectedOption == options[index]['_id'];

    return Opacity(
      opacity: 0.8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.5),
                  child: Icon(Icons.equalizer, color: Colors.white, size: 18.0),
                ),
                SizedBox(width: 4.0),
                Text('$votePercent%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
          DotsIndicator(
            dotsCount: widget.numImages,
            position: currentPosition,
            decorator: DotsDecorator(
              size: Size.square(6.0),
              color: Colors.white,
              activeColor: Theme.of(context).accentColor,
              activeSize: Size.square(6.0),
              spacing: const EdgeInsets.symmetric(horizontal: 2.5),
            ),
          ),
          Container(
            width: 100.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 1.5),
                  child: Icon(Icons.favorite,
                      color: selected ? Theme.of(context).accentColor : Colors.white, size: 15.0),
                ),
                SizedBox(width: 4.0),
                Text(
                  numberMethods.shortenNum(votes),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class PhotoHero extends StatelessWidget {
  const PhotoHero({Key key, this.tag, this.photo, this.onLongPress, this.onPanUpdate, this.width})
      : super(key: key);

  final String tag;
  final photo;
  final onLongPress;
  final onPanUpdate;
  final double width;

  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: GestureDetector(
        onLongPress: onLongPress,
        onPanUpdate: onPanUpdate,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: Image.memory(
            photo,
            fit: BoxFit.cover,
            width: width,
          ),
        ),
      ),
    );
  }
}

class TransparentRoute extends PageRoute<void> {
  TransparentRoute({
    @required this.builder,
    RouteSettings settings,
  })  : assert(builder != null),
        super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final options;
  final selectedOption;
  final vote;
  final isCreator;
  final completed;
  final getImages;

  ImageCarousel(
      {Key key,
      @required this.options,
      this.selectedOption,
      this.vote,
      this.isCreator,
      this.completed,
      this.getImages})
      : super(key: key);

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List options = widget.options;
    double screenWidth = MediaQuery.of(context).size.width - 20;
    double screenHeight = screenWidth - (screenWidth * 0.2);
    List imageBytesList = [];

    return FutureBuilder<List>(
        future: widget.getImages(options, imageBytesList),
        builder: (context, AsyncSnapshot<List> imageBytes) {
          if (imageBytes.hasData) {
            imageBytesList = imageBytesList + imageBytes.data;

            List<Widget> imageWidgets = [];

            int totalVotes = 0;

            for (var j = 0; j < options.length; j++) {
              totalVotes += options[j]['votes'];
            }

            if (imageWidgets.length == 0) {
              List imageBytesList = imageBytes.data;

              for (var i = 0; i < imageBytesList.length; i++) {
                var image = imageBytesList[i];

                imageWidgets.add(
                  GestureDetector(
                    onDoubleTap: () {
                      if (!widget.completed && !widget.isCreator) {
                        HapticFeedback.mediumImpact();
                        widget.vote(options[i]);
                      }
                    },
                    child: PhotoHero(
                      tag: options[i]['_id'],
                      photo: image,
                      width: screenWidth,
                      onPanUpdate: (details) {},
                      onLongPress: () async {
                        HapticFeedback.heavyImpact();
                        Navigator.of(context)
                            .push(TransparentRoute(builder: (BuildContext context) {
                          return BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhotoHero(
                                  tag: options[i]['_id'],
                                  photo: image,
                                  width: screenWidth,
                                  onPanUpdate: (details) {
                                    if (details.delta.dy > 0) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  onLongPress: () {},
                                ),
                                Container(
                                  height: 100.0,
                                ),
                              ],
                            ),
                          );
                        }));
                      },
                    ),
                  ),
                );
              }
            }

            return Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                    child: PageView(
                      children: imageWidgets,
                      controller: pageController,
                    ),
                  ),
                ),
                IgnorePointer(
                    child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black12, Colors.black45, Colors.black87],
                    ).createShader(Rect.fromLTRB(0, 0, screenWidth, screenHeight + 75));
                  },
                  blendMode: BlendMode.darken,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                        color: Colors.transparent),
                    width: screenWidth,
                    height: screenHeight,
                  ),
                )),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: PositionalDots(
                          pageController: pageController,
                          numImages: imageWidgets.length,
                          totalVotes: totalVotes,
                          options: options,
                          selectedOption: widget.selectedOption),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return new Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                color: Theme.of(context).hintColor,
              ),
              width: screenWidth,
              height: screenHeight,
            );
          }
        });
  }
}

class CategoryButton extends StatefulWidget {
  final followingCategories;
  final pollCategory;
  final warning;
  final parentController;
  final updatedUserModel;

  CategoryButton(
      {Key key,
      @required this.followingCategories,
      this.pollCategory,
      this.warning,
      this.parentController,
      this.updatedUserModel})
      : super(key: key);

  @override
  _CategoryButtonState createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  List followingCategories;
  bool warning;

  final streamController = StreamController();

  Future categoryAddFollower(String category, bool unfollow) async {
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
    var jsonResponse, user;

    String url = 'http://localhost:4000/user/' + userId;

    var headers = {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: token
        },
        response,
        body;

    response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      jsonResponse = jsonDecode(response.body);

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
          jsonResponse = jsonDecode(response.body);
          user = jsonResponse['user'];

          await categoryAddFollower(category, unfollow);
          widget.updatedUserModel(user);

          if (unfollow) {
            return showAlert(context, 'Successfully unfollowed category "' + category + '"', true);
          } else {
            return showAlert(context, 'Successfully followed category "' + category + '"', true);
          }
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
  void initState() {
    followingCategories = widget.followingCategories;

    widget.parentController.stream.asBroadcastStream().listen((options) {
      if (options['dataType'] == 'user') {
        var newUser = options['data'];
        if (mounted)
          setState(() {
            followingCategories = newUser['followingCategories'];
          });
      }
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

    super.initState();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var pollCategory = widget.pollCategory;

    return Container(
      height: 25.0,
      decoration: new BoxDecoration(
          color: followingCategories.contains(pollCategory)
              ? Theme.of(context).accentColor
              : Theme.of(context).hintColor,
          borderRadius: new BorderRadius.all(const Radius.circular(4.0))),
      child: GestureDetector(
        onTap: () {
          if (widget.warning) {
            showAlert(context, "You're going that too fast. Take a break.");
          }
          HapticFeedback.mediumImpact();
          streamController.add(pollCategory);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.0),
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
    );
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

  List options;
  List images;
  List followingCategories;

  bool saved = false;
  bool liked = false;
  bool warning = false;

  Future<List> getImages(List options, imageBytes) async {
    if (images == null && imageBytes != null && imageBytes.length == 0) {
      for (var option in options) {
        String url = option['content'];
        var response = await http.get(url);
        if (response.statusCode == 200) {
          imageBytes.add(response.bodyBytes);
        }
      }
      images = imageBytes;
    }
    return images;
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

    super.initState();
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

        if (mounted) {
          setState(() {
            user = jsonResponse['user'];
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

      createdPolls.remove(pollId);
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
      widget.parentController.add({
        'dataType': 'delete',
        'data': _id
      });

    } else {
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void handleAction(String action) {
    switch (action) {
      case 'delete':
        Widget cancelButton = FlatButton(
          child: Text("CANCEL", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.pop(context);
          },
        );

        Widget continueButton = FlatButton(
          child: Text("DELETE",
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.red)),
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

    bool isCreator = user['_id'] == pollCreator['_id'];
    bool completed = completedPolls.indexOf(poll['_id']) >= 0;
    bool categoryNotSelected = widget.currentCategory == null;
    double screenWidth = MediaQuery.of(context).size.width;
    String selectedOption;

    if (completed) {
      for (var c in options) {
        String _id = c['_id'];
        if (selectedOptions.contains(_id)) {
          selectedOption = _id;
        }
      }
    }

    ImageCarousel imageCarousel = new ImageCarousel(
        options: options,
        selectedOption: selectedOption,
        vote: vote,
        isCreator: isCreator,
        completed: completed,
        getImages: getImages);

    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            imageCarousel,
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: user['_id'] == pollCreator['_id']
                                ? screenWidth - 85
                                : screenWidth - 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(children: [
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
                                ]),

                                // TODO: COMPONENT
                                selectedOption != null
                                    ? Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 1.0),
                                            child: Icon(Icons.check_rounded,
                                                size: 18.0, color: Colors.green),
                                          ),
                                          SizedBox(width: 1.5),
                                          Text(
                                            'voted',
                                            style: TextStyle(
                                                color: Colors.green, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ],
                            ),
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
                                    builder: (BuildContext context) =>
                                        PollMenu(isCreator: isCreator));
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
                  Text(
                    poll['prompt'],
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: categoryNotSelected
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      categoryNotSelected
                          ? CategoryButton(
                              followingCategories: followingCategories,
                              pollCategory: pollCategory,
                              warning: warning,
                              parentController: widget.parentController,
                              updatedUserModel: widget.updatedUserModel)
                          : Container(),
                      GestureDetector(
                        onTap: () {
                          widget.viewPoll(poll['_id']);
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              poll['comments'] != null
                                  ? poll['comments'].length.toString() + ' '
                                  : '0 ',
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
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/colors.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/numMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/poll/pollMenu.dart';
import 'package:juneau/profile/profile.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class PositionalDots extends StatefulWidget {
  final pageController;
  final numImages;
  final totalVotes;
  final options;
  final selectedOption;
  final completed;
  final isCreator;

  PositionalDots({
    Key key,
    @required this.pageController,
    this.numImages,
    this.totalVotes,
    this.options,
    this.selectedOption,
    this.completed,
    this.isCreator,
  }) : super(key: key);

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
      if (mounted) {
        setState(() {
          double page = widget.pageController.page;
          currentPosition = page % options.length;
        });
      }
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

    return Stack(
      children: [
        widget.completed || widget.isCreator
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.equalizer, color: Colors.white, size: 20.0),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 1.0),
                            child: Text(
                              '$votePercent%',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 3.0),
                              child: Icon(Icons.check, color: Colors.white, size: 18.0),
                            )
                          : Container(width: 0, height: 0),
                    ],
                  ),
                ),
              )
            : Container(width: 0, height: 0),
        Align(
          alignment: Alignment.bottomCenter,
          child: DotsIndicator(
            dotsCount: widget.numImages,
            position: currentPosition,
            decorator: DotsDecorator(
              size: Size.square(6.0),
              color: customColors.grey,
              activeColor: Theme.of(context).highlightColor,
              activeSize: Size.square(6.0),
              spacing: const EdgeInsets.symmetric(horizontal: 2.5),
            ),
          ),
        ),
      ],
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
        child: Image.memory(
          photo,
          fit: BoxFit.cover,
          width: width,
        ),
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

  ImageCarousel({
    Key key,
    @required this.options,
    this.selectedOption,
    this.vote,
    this.isCreator,
    this.completed,
    this.getImages,
  }) : super(key: key);

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
    List options = widget.options..shuffle();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = screenWidth / 1.3;
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
                      onLongPress: () {},
                      // onLongPress: () async {
                      //   HapticFeedback.heavyImpact();
                      //   Navigator.of(context).push(
                      //     TransparentRoute(
                      //       builder: (BuildContext context) {
                      //         return Scaffold(
                      //           backgroundColor: Colors.transparent,
                      //           body: BackdropFilter(
                      //             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      //             child: Center(
                      //               child: PhotoHero(
                      //                 tag: options[i]['_id'],
                      //                 photo: image,
                      //                 width: screenWidth,
                      //                 onPanUpdate: (details) {
                      //                   if (details.delta.dy > 0) {
                      //                     Navigator.of(context).pop();
                      //                   }
                      //                 },
                      //                 onLongPress: () {},
                      //               ),
                      //             ),
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   );
                      // },
                    ),
                  ),
                );
              }
            }

            return Container(
              width: screenWidth,
              height: screenHeight + 22,
              child: Stack(
                children: [
                  Container(
                    height: screenHeight,
                    child: PageView.builder(
                      controller: pageController,
                      itemBuilder: (context, index) {
                        return imageWidgets[index % imageWidgets.length];
                      },
                    ),
                  ),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.35,
                      child: Container(
                        width: screenWidth,
                        height: screenHeight,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: PositionalDots(
                      pageController: pageController,
                      numImages: imageWidgets.length,
                      totalVotes: totalVotes,
                      options: options,
                      selectedOption: widget.selectedOption,
                      completed: widget.completed,
                      isCreator: widget.isCreator,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return new Container(
              color: customColors.grey,
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

    if (widget.parentController != null) {
      widget.parentController.stream.asBroadcastStream().listen((options) {
        if (options['dataType'] == 'user') {
          var newUser = options['data'];
          if (mounted)
            setState(() {
              followingCategories = newUser['followingCategories'];
            });
        }
      });
    }

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
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 20),
      decoration: new BoxDecoration(
        color: followingCategories.contains(pollCategory)
            ? Theme.of(context).buttonColor
            : Theme.of(context).backgroundColor,
        borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
        border: Border.all(
          color: Theme.of(context).buttonColor,
          width: 0.5,
          style: BorderStyle.solid,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.warning) {
            showAlert(context, "You're going that too fast. Take a break.");
          }
          HapticFeedback.mediumImpact();
          streamController.add(pollCategory);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
          child: Text(
            pollCategory,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: followingCategories.contains(pollCategory)
                  ? Theme.of(context).backgroundColor
                  : Theme.of(context).buttonColor,
            ),
          ),
        ),
      ),
    );
  }
}

class PollWidget extends StatefulWidget {
  final poll;
  final options;
  final images;
  final user;
  final dismissPoll;
  final viewPoll;
  final index;
  final updatedUserModel;
  final parentController;

  PollWidget(
      {Key key,
      @required this.poll,
      this.options,
      this.images,
      this.user,
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
  var profilePhoto;
  String profilePhotoUrl;

  List options;
  List images;
  List followingCategories;

  bool saved = false;
  bool liked = false;
  bool warning = false;
  bool profileFetched = false;

  Future<List> getImages(List options, imageBytes) async {
    if (images == null) {
      images = [];
      for (var option in options) {
        String url = option['content'];
        var bodyBytes = await imageMethods.getImage(url);
        images.add(bodyBytes);
      }
    }
    if (imageBytes == null) {
      imageBytes = images;
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
    options = widget.options;
    images = widget.images;

    followingCategories = user['followingCategories'];

    userMethods.getUser(poll['createdBy']).then((pollUser) async {
      if (pollUser != null) {
        pollCreator = pollUser;
      }

      profilePhotoUrl = pollCreator['profilePhoto'];

      if (profilePhoto == null && profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }
      profileFetched = true;

      if (options == null) {
        _getOptions(poll).then((pollOptions) {
          if (mounted) {
            setState(() {
              if (pollOptions != null && pollOptions.length > 0) {
                options = pollOptions;
              }
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {});
        }
      }
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
    String token = prefs.getString('token');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    List keys = [];

    for (var i = 0; i < options.length; i++) {
      var url = options[i]['content'], split = url.split('/'), key = split[split.length - 1];

      keys.add({'Key': key});
    }

    var body = jsonEncode({'optionsList': options});
    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      showAlert(context, 'Successfully deleted poll', true);
      imageMethods.deleteFiles(keys, 'poll-option');
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
      widget.parentController.add({'dataType': 'delete', 'data': _id});
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
    String time = timeago.format(createdAt, locale: 'en_short').replaceAll(new RegExp(r'~'), '');

    var completedPolls = user['completedPolls'];
    var selectedOptions = user['selectedOptions'];

    bool isCreator = user['_id'] == pollCreator['_id'];
    bool completed = completedPolls != null ? completedPolls.indexOf(poll['_id']) >= 0 : false;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = screenWidth / 1.3;
    int totalVotes = 0;
    String prompt = poll['prompt'];
    String selectedOption;

    for (var c in options) {
      String _id = c['_id'];
      int votes = c['votes'];

      totalVotes += votes;

      if (completed && selectedOptions.contains(_id)) {
        selectedOption = _id;
      }
    }

    ImageCarousel imageCarousel = new ImageCarousel(
      options: options,
      selectedOption: selectedOption,
      vote: vote,
      isCreator: isCreator,
      completed: completed,
      getImages: getImages,
    );

    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth / 1.5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      child: profilePhoto != null
                                          ? Container(
                                              width: 26,
                                              height: 26,
                                              child: ClipOval(
                                                child: Image.memory(
                                                  profilePhoto,
                                                  fit: BoxFit.cover,
                                                  width: 26.0,
                                                  height: 26.0,
                                                ),
                                              ),
                                            )
                                          : CircleAvatar(
                                              radius: 13,
                                              backgroundColor: Colors.transparent,
                                              backgroundImage: profileFetched
                                                  ? AssetImage('images/profile.png')
                                                  : null,
                                            ),
                                      onTap: () {
                                        openProfile(context, pollCreator, user: user);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                            child: Text(
                                              pollCreator['username'],
                                              style: TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: () {
                                              openProfile(context, pollCreator, user: user);
                                            }),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(2.0, 1.0, 2.0, 0.0),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              fontSize: 13.0,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 1.5),
                                          child: Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              wordSpacing: -3.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                              size: 20,
                            ),
                          )
                        : Container(),
                  ],
                ),
                prompt.trim() != ''
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          prompt,
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      )
                    : SizedBox(height: 3.0),
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: CategoryButton(
                    followingCategories: followingCategories,
                    pollCategory: pollCategory,
                    warning: warning,
                    parentController: widget.parentController,
                    updatedUserModel: widget.updatedUserModel,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: screenHeight + 35,
            child: Stack(
              children: [
                imageCarousel,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Wrap(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.how_to_vote,
                                        color: Theme.of(context).buttonColor, size: 20.0),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 1.0),
                                      child: Text(
                                        numberMethods.shortenNum(totalVotes),
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.viewPoll(poll['_id']);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(math.pi),
                                        child: Icon(
                                          Icons.messenger_outline,
                                          size: 20.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 1.0),
                                        child: Text(
                                          poll['comments'] != null
                                              ? poll['comments'].length.toString()
                                              : '0',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

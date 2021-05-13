import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:juneau/common/colors.dart';

import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/methods/categoryMethods.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/notificationMethods.dart';
import 'package:juneau/common/methods/numMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/poll/pollMenu.dart';
import 'package:juneau/profile/profile.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:animated_check/animated_check.dart';

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
  bool _visible = true;
  List options;

  @override
  void initState() {
    options = widget.options;
    currentPosition = 0.0;

    widget.pageController.addListener(() {
      if (mounted) {
        double page = widget.pageController.page;
        currentPosition = page.roundToDouble();
        setState(() {
          _visible = true;
          if (widget.completed || widget.isCreator) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              setState(() {
                _visible = false;
              });
            });
          }
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

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      curve: Curves.easeOut,
      duration: Duration(milliseconds: _visible ? 250 : 500),
      child: Stack(
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: widget.completed || widget.isCreator ? 0.50 : 0.0,
              child: Container(
                color: Colors.black45,
              ),
            ),
          ),
          widget.completed || widget.isCreator
          ? Stack(
            children: [
              Align(
                alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '$votePercent%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              selected
                ? Center(child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Icon(Icons.check, color: Colors.white, size: 18.0),
                ))
                : Container(),
            ],
          )
              : Container(width: 0, height: 0),
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DotsIndicator(
                dotsCount: widget.numImages,
                position: currentPosition,
                decorator: DotsDecorator(
                  size: Size.square(5.0),
                  color: customColors.lightGrey,
                  activeColor: customColors.white,
                  activeSize: Size.square(5.0),
                  spacing: const EdgeInsets.symmetric(horizontal: 2.5),
                ),
              ),
            ),
          ),
        ],
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

class _ImageCarouselState extends State<ImageCarousel> with SingleTickerProviderStateMixin {
  PageController pageController = PageController();

  AnimationController _animationController;
  Animation _animation;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = new Tween<double>(begin: 0, end: 1)
      .animate(
        new CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInCirc,
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List options = widget.options;
    double screenWidth = MediaQuery.of(context).size.width;
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
                        _animationController.forward();
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          setState(() {
                            _visible = false;
                            widget.vote(options[i]);
                          });
                        });
                      }
                    },
                    child: Image.memory(
                      image,
                      fit: BoxFit.cover,
                      width: screenWidth,
                    ),
                  ),
                );
              }
            }

            return Container(
              width: screenWidth,
              height: screenWidth,
              child: Stack(
                children: [
                  Container(
                    height: screenWidth,
                    child: PageView(
                      controller: pageController,
                      children: imageWidgets,
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
                  _visible
                  ? Align(
                    alignment: Alignment.center,
                    child: AnimatedCheck(
                      progress: _animation,
                      color: customColors.white,
                      size: 100,
                    ),
                  )
                  : Container(),
                ],
              ),
            );
          } else {
            return new Container(
              color: Theme.of(context).dividerColor,
              width: screenWidth,
              height: screenWidth,
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

    streamController.stream.throttleTime(Duration(milliseconds: 1000)).listen((category) async {
      bool unfollow = false;
      if (followingCategories.contains(category)) {
        unfollow = true;
      }

      warning = true;
      Timer(Duration(milliseconds: 1000), () {
        warning = false;
      });

      var updatedUser =
          await categoryMethods.followCategory(category, unfollow, followingCategories);

      if (updatedUser != null) {
        widget.updatedUserModel(updatedUser);
        if (unfollow) {
          showAlert(context, 'Successfully unfollowed category "' + category + '"', true);
        } else {
          showAlert(context, 'Successfully followed category "' + category + '"', true);
        }
      } else {
        showAlert(context, 'Something went wrong, please try again');
      }
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
      decoration: new BoxDecoration(
        color: followingCategories.contains(pollCategory)
            ? Theme.of(context).backgroundColor
            : Theme.of(context).buttonColor,
        borderRadius: new BorderRadius.all(
          const Radius.circular(20.0),
        ),
        border: Border.all(
          color: followingCategories.contains(pollCategory)
            ? Theme.of(context).primaryColor
            : Theme.of(context).buttonColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 6.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                pollCategory,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: followingCategories.contains(pollCategory)
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).backgroundColor,
                ),
              ),
            ],
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
    String url = API_URL + 'option';

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
    String url = API_URL + 'option/vote/' + option['_id'].toString();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.put(url, headers: headers);

    if (response.statusCode == 200) {
      notificationMethods.createNotification(user['_id'], poll['createdBy'], 'has voted on your poll.', pollId: poll['_id']);

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
    String url = API_URL + 'user/';

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
    String url = API_URL + 'user/';

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
    String url = API_URL + 'options/delete';

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
      imageMethods.deleteFiles(keys);
      widget.dismissPoll(widget.index);
    } else {
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void deletePoll() async {
    String _id = poll['_id'];
    String url = API_URL + 'poll/' + _id;

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
        Widget cancelButton = RawMaterialButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
          constraints: BoxConstraints(),
          padding: EdgeInsets.symmetric(vertical: 15.0),
          fillColor: Theme.of(context).backgroundColor,
          elevation: 0.0,
          child: Text(
            'CANCEL',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
        );

        Widget continueButton = RawMaterialButton(
          onPressed: () {
            deletePoll();
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
          constraints: BoxConstraints(),
          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          fillColor: Theme.of(context).backgroundColor,
          elevation: 0.0,
          child: Text(
            'DELETE',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    String time = timeago.format(createdAt, locale: 'en_short'); // .replaceAll(new RegExp(r'~'), '');

    var completedPolls = user['completedPolls'];
    var selectedOptions = user['selectedOptions'];

    bool isCreator = user['_id'] == pollCreator['_id'];
    bool completed = completedPolls != null ? completedPolls.indexOf(poll['_id']) >= 0 : false;
    int totalVotes = 0;
    String prompt = poll['prompt'].trim();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          openProfile(context, pollCreator, user: user);
                        },
                        child: profilePhoto != null
                            ? Container(
                                width: 34,
                                height: 34,
                                child: ClipOval(
                                  child: Image.memory(
                                    profilePhoto,
                                    fit: BoxFit.cover,
                                    width: 34.0,
                                    height: 34.0,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 17.0,
                                backgroundColor: Colors.transparent,
                                backgroundImage: profileFetched
                                    ? AssetImage('images/profile.png')
                                    : null,
                              ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            },
                        ),
                        Row(
                          children: [
                            Text(
                              'posted $time ago',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CategoryButton(
                      followingCategories: followingCategories,
                      pollCategory: pollCategory,
                      warning: warning,
                      parentController: widget.parentController,
                      updatedUserModel: widget.updatedUserModel,
                    ),
                    user['_id'] == pollCreator['_id']
                        ? Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: GestureDetector(
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
                            ),
                        )
                        : Container(),
                  ],
                ),
              ],
            ),
          ),
          prompt != ''
            ? Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 15.0),
              child: Text(
                prompt,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
            : Container(height: 20.0),

          imageCarousel,

          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                totalVotes == 1 ? '1 vote' : numberMethods.shortenNum(totalVotes) + ' votes',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Padding(
          //   padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
          //   child: Align(
          //     alignment: Alignment.bottomCenter,
          //     child: Wrap(
          //       children: [
          //         Row(
          //           crossAxisAlignment: CrossAxisAlignment.end,
          //           children: [
          //             Row(
          //               crossAxisAlignment: CrossAxisAlignment.center,
          //               children: [
          //                 Icon(
          //                   Icons.check,
          //                   color: Theme.of(context).primaryColor,
          //                   size: 28.0,
          //                 ),
          //                 Text(
          //                   numberMethods.shortenNum(totalVotes),
          //                 ),
          //               ],
          //             ),
          //             GestureDetector(
          //               onTap: () {
          //                 widget.viewPoll(poll['_id']);
          //               },
          //               child: Padding(
          //                 padding: const EdgeInsets.only(left: 15.0),
          //                 child: Row(
          //                   crossAxisAlignment: CrossAxisAlignment.center,
          //                   children: [
          //                     Transform(
          //                       alignment: Alignment.center,
          //                       transform: Matrix4.rotationY(math.pi),
          //                       child: Icon(
          //                         Icons.messenger_outline,
          //                         size: 24.0,
          //                       ),
          //                     ),
          //                     Text(
          //                       poll['comments'] != null
          //                         ? poll['comments'].length.toString()
          //                         : '0',
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),


        ],
      ),
    );
  }
}

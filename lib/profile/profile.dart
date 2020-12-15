import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/components/keepAlivePage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/poll/pollPreview.dart';
import 'package:juneau/poll/poll.dart';
import 'package:juneau/comment/commentsPage.dart';
import 'package:juneau/settings/accountSettings.dart';
import 'package:juneau/profile/editProfile.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

void openProfile(context, profileUser, {user}) {
  Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          toolbarHeight: 30.0,
          backgroundColor: Theme.of(context).backgroundColor,
          brightness: Theme.of(context).brightness,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 25.0,
              color: Theme.of(context).buttonColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ProfilePage(profileUser: profileUser, user: user));
  }));
}

class PollListPopover extends StatefulWidget {
  final selectedIndex;
  final user;
  final pollObjects;
  final pollListController;
  final dismissPoll;
  final viewPoll;
  final updatedUserModel;
  final parentController;
  final tag;

  PollListPopover(
      {Key key,
      @required this.selectedIndex,
      this.user,
      this.pollObjects,
      this.pollListController,
      this.dismissPoll,
      this.viewPoll,
      this.updatedUserModel,
      this.parentController,
      this.tag})
      : super(key: key);

  @override
  _PollListPopoverState createState() => _PollListPopoverState();
}

class _PollListPopoverState extends State<PollListPopover> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  List<Widget> pollsList;
  List pollObjects;
  int visibleIndex;

  @override
  void initState() {
    pollObjects = widget.pollObjects;

    widget.pollListController.stream.listen((updatedPollObjects) {
      setState(() {
        pollObjects = updatedPollObjects;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      itemScrollController.jumpTo(index: widget.selectedIndex);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Hero(
              tag: widget.tag,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
              )),
        ),
        Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).backgroundColor,
            brightness: Theme.of(context).brightness,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 25.0,
                color: Theme.of(context).buttonColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.user['username'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).buttonColor,
              ),
            ),
          ),
          body: pollObjects != null && pollObjects.length > 0
              ? ScrollablePositionedList.builder(
                  itemCount: pollObjects.length + 1,
                  itemBuilder: (context, index) {
                    if (index == pollObjects.length) {
                      return SizedBox(height: 43);
                    }

                    var pollObject = pollObjects[index],
                        poll = pollObject['poll'],
                        options = pollObject['options'],
                        images = pollObject['images'];

                    return Container(
                      key: UniqueKey(),
                      child: PollWidget(
                          poll: poll,
                          options: options,
                          images: images,
                          user: widget.user,
                          dismissPoll: widget.dismissPoll,
                          viewPoll: widget.viewPoll,
                          index: index,
                          updatedUserModel: widget.updatedUserModel,
                          parentController: widget.parentController),
                    );
                  },
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: Center(child: Container(child: Text('No created polls found'))),
                ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  final profileUser;
  final user;

  ProfilePage({
    Key key,
    @required this.profileUser,
    this.user,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var profileUser;
  var user;
  String userId;
  String prevId;
  Widget gridListView;
  List pollObjects;
  BuildContext profileContext;

  bool pollOpen = false;
  bool preventReload = false;
  bool following = false;
  bool isUser;

  bool alreadyPressed = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);
  StreamController pollListController = StreamController.broadcast();
  var parentController;

  Future<List> getPollsFromUser() async {
    const url = 'http://localhost:4000/polls';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'prevId': prevId, 'createdBy': profileUser['_id']});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse.length > 0) {
        prevId = jsonResponse.last['_id'];
      }

      return jsonResponse;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return [];
    }
  }

  Future fetchPollData(bool next) async {
    List polls = await getPollsFromUser();

    if (pollObjects == null ||
        (next && polls.length > 0) ||
        (!next && polls.length != pollObjects.length)) {
      if (!next) {
        pollObjects = [];
      }
      for (int i = 0; i < polls.length; i++) {
        var poll = polls[i];
        pollObjects.add({
          'index': i,
          'poll': poll,
        });
      }
      setState(() {
        preventReload = false;
      });
    }
  }

  @override
  void initState() {
    profileUser = widget.profileUser;
    user = widget.user;
    prevId = null;
    parentController = new StreamController.broadcast();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String profileUserId = profileUser['_id'];

      if (user != null) {
        userId = user['_id'];
        following = user['followingUsers'].contains(profileUserId);
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
      }
      isUser = userId == profileUserId;

      await fetchPollData(false);
    });

    super.initState();
  }

  Widget createGridList() {
    List<Widget> pollsList = [];
    List<Widget> gridRow = [];

    for (int i = 0; i < pollObjects.length; i++) {
      var pollObject = pollObjects[i];

      gridRow.add(Hero(
        tag: pollObject['poll']['_id'],
        child: PollPreview(
          pollObject: pollObject,
          openListView: openListView,
        ),
      ));

      if ((i + 1) % 3 == 0 || i == pollObjects.length - 1) {
        pollsList.add(
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gridRow),
        );
        gridRow = [];
      }
    }

    return Column(
      children: pollsList,
    );
  }

  @override
  void dispose() {
    refreshController.dispose();
    pollListController.close();
    parentController.close();
    super.dispose();
  }

  void updatedUserModel(updatedUser) {
    profileUser = updatedUser;
    parentController.add({'dataType': 'user', 'data': profileUser});
  }

  void dismissPoll(index) {
    if (mounted) {
      setState(() {
        preventReload = false;
        pollObjects.removeAt(index);
        pollListController.add(pollObjects);
      });
    }
  }

  void viewPoll(String pollId) async {
    if (!pollOpen) {
      pollOpen = true;
      final _formKey = GlobalKey<FormState>();

      Navigator.of(profileContext).push(TransparentRoute(builder: (BuildContext context) {
        return CommentsPage(user: profileUser, pollId: pollId, formKey: _formKey);
      }));

      pollOpen = false;
    }
  }

  void _onRefresh() async {
    prevId = null;
    await fetchPollData(false);
    refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (pollObjects.length == profileUser['createdPolls'].length) return;
    await fetchPollData(true);
    refreshController.loadComplete();
  }

  void openListView(index, tag) async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
          selectedIndex: index,
          user: profileUser,
          pollObjects: pollObjects,
          pollListController: pollListController,
          dismissPoll: dismissPoll,
          viewPoll: viewPoll,
          updatedUserModel: updatedUserModel,
          parentController: parentController,
          tag: tag);
    }));
  }

  Future updateUser(followingUsers) async {
    String url = 'http://localhost:4000/user/' + userId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'followingUsers': followingUsers});

    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
      if (msg == null) {
        msg = 'Something went wrong, please try again';
      }
      showAlert(profileContext, msg);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pollObjects != null && !preventReload) {
      preventReload = true;
      profileContext = context;
      gridListView = createGridList();
    }

    return KeepAlivePage(
      child: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: ClassicHeader(),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
        ),
        controller: refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
              child: Text(
                profileUser['username'],
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.3,
                ),
              ),
            ),
            profileUser['description'] != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                    child: Text(
                      profileUser['description'],
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: isUser != null && isUser
                    ? [
                        RawMaterialButton(
                          onPressed: () async {
                            var update = await showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return new EditProfileModal(
                                    user: profileUser,
                                  );
                                });

                            setState(() {
                              profileUser = update['user'];
                            });
                          },
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                          fillColor: Theme.of(context).backgroundColor,
                          elevation: 0.0,
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Theme.of(context).buttonColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: Theme.of(context).hintColor,
                                  width: 1,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        SizedBox(width: 5.0),
                        RawMaterialButton(
                          onPressed: () {
                            showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (BuildContext context) =>
                                    AccountSettings(user: profileUser));
                          },
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                          fillColor: Theme.of(context).backgroundColor,
                          elevation: 0.0,
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              color: Theme.of(context).buttonColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: Theme.of(context).hintColor,
                                  width: 1,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(5)),
                        ),
                      ]
                    : [
                        RawMaterialButton(
                          onPressed: () async {
                            if (!alreadyPressed) {
                              alreadyPressed = true;
                            } else {
                              return showAlert(profileContext, 'Going too fast.');
                            }

                            List followingUsers =
                                user['followingUsers'] != null ? user['followingUsers'] : [];
                            String profileUserId = profileUser['_id'];

                            if (following) {
                              followingUsers.remove(profileUserId);
                            } else {
                              followingUsers.add(profileUserId);
                            }

                            var updatedUser = await updateUser(followingUsers);
                            if (updatedUser != null) {
                              setState(() {
                                user = updatedUser;
                                following = followingUsers.contains(profileUserId);
                                alreadyPressed = false;
                              });
                            }
                          },
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                          fillColor: following
                              ? Theme.of(context).accentColor
                              : Theme.of(context).backgroundColor,
                          elevation: 0.0,
                          child: Text(
                            following ? 'Unfollow' : 'Follow',
                            style: TextStyle(
                              color: following
                                  ? Theme.of(context).backgroundColor
                                  : Theme.of(context).buttonColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: following
                                      ? Theme.of(context).accentColor
                                      : Theme.of(context).hintColor,
                                  width: 1,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        // SizedBox(width: 5.0),
                        // RawMaterialButton(
                        //   onPressed: () {},
                        //   constraints: BoxConstraints(),
                        //   padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                        //   fillColor: Theme.of(context).backgroundColor,
                        //   elevation: 0.0,
                        //   child: Text(
                        //     'Message',
                        //     style: TextStyle(
                        //       color: Theme.of(context).buttonColor,
                        //       fontWeight: FontWeight.w500,
                        //     ),
                        //   ),
                        //   shape: RoundedRectangleBorder(
                        //       side: BorderSide(
                        //           color: Theme.of(context).hintColor,
                        //           width: 1,
                        //           style: BorderStyle.solid),
                        //       borderRadius: BorderRadius.circular(5)),
                        // ),
                      ],
              ),
            ),
            pollObjects != null
                ? pollObjects.length > 0
                    ? gridListView
                    : Padding(
                        padding: const EdgeInsets.only(top: 100.0),
                        child: Center(
                          child: Container(child: Text('No created polls found')),
                        ),
                      )
                : Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Center(
                      child: Container(child: CircularProgressIndicator()),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

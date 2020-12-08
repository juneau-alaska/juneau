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

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PollListPopover extends StatefulWidget {
  final selectedIndex;
  final user;
  final pollObjects;
  final pollListController;
  final dismissPoll;
  final viewPoll;
  final updatedUserModel;
  final parentController;

  PollListPopover({
    Key key,
    @required this.selectedIndex,
    this.user,
    this.pollObjects,
    this.pollListController,
    this.dismissPoll,
    this.viewPoll,
    this.updatedUserModel,
    this.parentController,
  }) : super(key: key);

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
    return Scaffold(
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
              child: Container(child: Text('No created polls found')),
            ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final user;

  ProfilePage({
    Key key,
    @required this.user,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var user;
  String prevId;
  Widget gridListView;
  List pollObjects;
  BuildContext profileContext;

  bool pollOpen = false;
  bool preventReload = false;
  bool isUser;

  RefreshController refreshController = RefreshController(initialRefresh: false);
  StreamController pollListController = StreamController.broadcast();
  var parentController;

  void logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs?.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
  }

  Future<List> getPollsFromUser() async {
    const url = 'http://localhost:4000/polls';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'prevId': prevId, 'createdBy': user['_id']});

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
    user = widget.user;
    prevId = null;
    parentController = new StreamController.broadcast();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId');
      isUser = userId == user['_id'];

      await fetchPollData(false);
    });

    super.initState();
  }

  Widget createGridList() {
    List<Widget> pollsList = [];
    List<Widget> gridRow = [];

    for (int i = 0; i < pollObjects.length; i++) {
      var pollObject = pollObjects[i];

      gridRow.add(PollPreview(
        pollObject: pollObject,
        openListView: openListView,
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
    user = updatedUser;
    parentController.add({'dataType': 'user', 'data': user});
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
        return CommentsPage(user: user, pollId: pollId, formKey: _formKey);
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
    if (pollObjects.length == user['createdPolls'].length) return;
    await fetchPollData(true);
    refreshController.loadComplete();
  }

  void openListView(index) async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
        selectedIndex: index,
        user: user,
        pollObjects: pollObjects,
        pollListController: pollListController,
        dismissPoll: dismissPoll,
        viewPoll: viewPoll,
        updatedUserModel: updatedUserModel,
        parentController: parentController,
      );
    }));
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
              padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
              child: Text(
                user['username'],
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: isUser != null && isUser
                    ? [
                        RawMaterialButton(
                          onPressed: () {},
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
                          onPressed: () {},
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
                          onPressed: () {},
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                          fillColor: Theme.of(context).backgroundColor,
                          elevation: 0.0,
                          child: Text(
                            'Follow',
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
                          onPressed: () {},
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                          fillColor: Theme.of(context).backgroundColor,
                          elevation: 0.0,
                          child: Text(
                            'Message',
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

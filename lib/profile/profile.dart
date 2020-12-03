import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/components/keepAlivePage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/poll/pollPreview.dart';
import 'package:juneau/poll/poll.dart';
import 'package:juneau/poll/pollPage.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PollListPopover extends StatefulWidget {
  final user;
  final pollObjects;
  final pollListController;
  final dismissPoll;
  final viewPoll;
  final updatedUserModel;
  final parentController;

  PollListPopover({
    Key key,
    @required this.user,
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
  List<Widget> pollsList = [];
  List pollObjects;

  void createPolls() {
    for (int i = 0; i < pollObjects.length; i++) {
      var pollObject = pollObjects[i],
        poll = pollObject['poll'],
        options = pollObject['options'],
        images = pollObject['images'];

      pollsList.add(Container(
        key: UniqueKey(),
        child: PollWidget(
          poll: poll,
          options: options,
          images: images,
          user: widget.user,
          dismissPoll: widget.dismissPoll,
          viewPoll: widget.viewPoll,
          index: i,
          updatedUserModel: widget.updatedUserModel,
          parentController: widget.parentController
        ),
      ));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    pollObjects = widget.pollObjects;

    createPolls();

    widget.pollListController.stream.listen((updatedPollObjects) {
      pollObjects = updatedPollObjects;
      createPolls();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        children: [
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back,
                        size: 25.0,
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.user['username'],
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 30,
                ),
              ],
            ),
          ),
          Flexible(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                physics: ClampingScrollPhysics(),
                children: pollsList,
              ),
            ),
          ),
        ],
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

  RefreshController refreshController = RefreshController(initialRefresh: false);
  StreamController pollListController = StreamController();
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
      return null;
    }
  }

  Future fetchPollData(bool next) async {
    if (!next) {
      pollObjects = [];
    }
    List polls = await getPollsFromUser();

    for (int i = 0; i < polls.length; i++) {
      var poll = polls[i];
      pollObjects.add({
        'index': i,
        'poll': poll,
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    user = widget.user;
    prevId = null;
    parentController = new StreamController.broadcast();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

    return ListView(
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
      await showDialog(
        context: profileContext,
        builder: (context) => PollPage(user: user, pollId: pollId, formKey: _formKey),
        barrierColor: Color(0x01000000));
      pollOpen = false;
    }
  }

  void _onRefresh() async {
    preventReload = false;
    prevId = null;
    await fetchPollData(false);
    refreshController.refreshCompleted();
  }

  void _onLoading() async {
    preventReload = false;
    await fetchPollData(true);
    refreshController.loadComplete();
  }

  void openListView() async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          child: Text(
            user['username'],
            style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Follow',
                ),
              ),
              SizedBox(width: 5.0),
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Message',
                ),
              )
            ],
          ),
        ),
        pollObjects != null
            ? pollObjects.length > 0
                ? Flexible(
                    child: KeepAlivePage(
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
                        child: gridListView,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 50.0),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/views/appBar.dart';
import 'package:juneau/common/views/navBar.dart';
import 'package:juneau/poll/poll.dart';
import 'package:juneau/poll/pollPage.dart';
import 'package:juneau/common/components/keepAlivePage.dart';
import 'package:juneau/common/components/alertComponent.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

String prevId;

Future<List> getPolls(context) async {
  const url = 'http://localhost:4000/polls';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  var body = jsonEncode({'prevId': prevId});

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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var user;
  List polls;
  List<Widget> pages;
  List<Widget> pollsList;
  SmartRefresher listViewBuilder;
  bool preventReload = false;

  _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId');

    await Future.wait([
      userMethods.getUser(userId),
      getPolls(context),
    ]).then((results) {
      var userResult = results[0], pollsResult = results[1];

      if (userResult != null) {
        user = userResult[0];
      }
      if (pollsResult != null) {
        polls = pollsResult;
      }
    });

    if (mounted) setState(() {});
  }

  final parentController = new StreamController.broadcast();

  void updatedUserModel(updatedUser) {
    user = updatedUser;
    parentController.add(user);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchData();
    });
    super.initState();
  }

  RefreshController refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async {
    preventReload = false;
    prevId = null;
    await _fetchData();
    refreshController.refreshCompleted();
  }

  void _onLoading() async {
    preventReload = true;
    var nextPolls = await getPolls(context);
    if (nextPolls != null && nextPolls.length > 0) {
      if (mounted)
        setState(() {
          polls += nextPolls;
        });
    }
    refreshController.loadComplete();
  }

  @override
  void dispose() {
    parentController.close();
    refreshController.dispose();
    super.dispose();
  }

  void dismissPoll(index) {
    setState(() {
      pollsList.removeAt(index);
    });
  }

  void viewPoll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PollPage();
      },
    );
  }

  void createPages(polls, user) {
    pollsList = [];
    for (var i = 0; i < polls.length; i++) {
      var poll = polls[i];
      pollsList.add(new PollWidget(
          poll: poll,
          user: user,
          dismissPoll: dismissPoll,
          viewPoll: viewPoll,
          index: i,
          updatedUserModel: updatedUserModel,
          parentController: parentController));
    }

    listViewBuilder = SmartRefresher(
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: pollsList,
      )
    );

    pages = [KeepAlivePage(child: listViewBuilder)];
  }

  @override
  Widget build(BuildContext context) {
    if (polls == null) {
      return new Container();
    }

    if (!preventReload) {
      preventReload = false;
      createPages(polls, user);
    }

    return Scaffold(
      key: UniqueKey(),
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: appBar(),
      body: PageView(
        children: pages,
      ),
      bottomNavigationBar: navBar(),
    );
  }
}

import 'package:flutter/cupertino.dart';
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

var user;
String prevId;
String currentCategory;
StreamController categoryStreamController;

Future<List> getPolls(context) async {
  const url = 'http://localhost:4000/polls';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode({'prevId': prevId, 'category': currentCategory});

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

class CategoryTabs extends StatefulWidget {
  @override
  _CategoryTabsState createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  List followingCategories = user['followingCategories'];
  List<Widget> categoryTabs;

  @override
  Widget build(BuildContext context) {
    categoryTabs = [
      Padding(
        padding: const EdgeInsets.only(right: 3.0),
        child: FlatButton(
          onPressed: () {
            categoryStreamController.add(null);
          },
          color: currentCategory == null
              ? Theme.of(context).accentColor
              : Theme.of(context).backgroundColor,
          child: Text(
            'All',
            style: TextStyle(
              color: currentCategory == null
                  ? Theme.of(context).backgroundColor
                  : Theme.of(context).buttonColor,
            ),
          ),
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: currentCategory == null
                      ? Theme.of(context).accentColor
                      : Theme.of(context).hintColor,
                  width: 1,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(50)),
        ),
      ),
    ];

    for (var i = 0; i < followingCategories.length; i++) {
      String category = followingCategories[i];
      categoryTabs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: FlatButton(
            onPressed: () {
              categoryStreamController.add(category);
            },
            color: currentCategory == category
                ? Theme.of(context).accentColor
                : Theme.of(context).backgroundColor,
            child: Text(
              category,
              style: TextStyle(
                color: currentCategory == category
                    ? Theme.of(context).backgroundColor
                    : Theme.of(context).buttonColor,
              ),
            ),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: currentCategory == category
                        ? Theme.of(context).accentColor
                        : Theme.of(context).hintColor,
                    width: 1,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(50)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        height: 38.0,
        width: MediaQuery.of(context).size.width - 20,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: categoryTabs,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List polls;
  List<Widget> pollsList;
  SmartRefresher listViewBuilder;
  bool preventReload = false;
  CategoryTabs categoryTabs;

  _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId');

    await Future.wait([
      userMethods.getUser(userId),
      getPolls(context),
    ]).then((results) {
      var userResult = results[0], pollsResult = results[1];

      if (userResult != null) {
        user = userResult;
        categoryTabs = new CategoryTabs();
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
    categoryStreamController = StreamController();
    categoryStreamController.stream.listen((category) async {
      prevId = null;
      currentCategory = category;
      await _fetchData();
    });

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
    categoryStreamController.close();
    super.dispose();
  }

  void dismissPoll(index) {
    setState(() {
      pollsList.removeAt(index);
    });
  }

  bool pollOpen = false;

  void viewPoll(String pollId) async {
    if (!pollOpen) {
      pollOpen = true;
      final _formKey = GlobalKey<FormState>();
      await showDialog(
          context: context,
          builder: (context) =>
              PollPage(user: user, pollId: pollId, formKey: _formKey),
          barrierColor: Color(0x01000000));
      pollOpen = false;
    }
  }

  void createPages(polls, user) {
    pollsList = [];
    for (var i = 0; i < polls.length; i++) {
      var poll = polls[i];
      pollsList.add(new PollWidget(
          poll: poll,
          user: user,
          currentCategory: currentCategory,
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
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: pollsList.length,
          itemBuilder: (context, index) {
            return pollsList[index];
          },
        ));
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: categoryTabs,
          ),
          Flexible(
            child: KeepAlivePage(
              child: listViewBuilder
            )
          ),
        ],
      ),
      bottomNavigationBar: navBar(),
    );
  }
}

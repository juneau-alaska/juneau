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
var parentController;
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
  void initState() {
    parentController.stream.asBroadcastStream().listen((options) {
      String dataType = options['dataType'];

      if (dataType == 'user') {
        var newUser = options['data'];
        if (mounted)
          setState(() {
            followingCategories = newUser['followingCategories'];
          });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    categoryTabs = [
      Padding(
        padding: const EdgeInsets.only(right: 3.0),
        child: RawMaterialButton(
          onPressed: () {
            categoryStreamController.add(null);
          },
          constraints: BoxConstraints(),
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          fillColor: currentCategory == null
              ? Theme.of(context).accentColor
              : Theme.of(context).backgroundColor,
          elevation: 0.0,
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
          child: RawMaterialButton(
            onPressed: () {
              categoryStreamController.add(category);
            },
            constraints: BoxConstraints(),
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            fillColor: currentCategory == category
                ? Theme.of(context).accentColor
                : Theme.of(context).backgroundColor,
            elevation: 0.0,
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
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
      child: Container(
        height: 35.0,
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
  BuildContext homeContext;
  Widget listViewBuilder;
  CategoryTabs categoryTabs;

  bool preventReload = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId');

    await Future.wait([
      userMethods.getUser(userId),
      getPolls(homeContext),
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

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    parentController = new StreamController.broadcast();
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

  void updatedUserModel(updatedUser) {
    user = updatedUser;
    parentController.add({'dataType': 'user', 'data': user});
  }

  void _onRefresh() async {
    preventReload = false;
    prevId = null;
    await _fetchData();
    refreshController.refreshCompleted();
  }

  void _onLoading() async {
    preventReload = false;
    var nextPolls = await getPolls(homeContext);
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
    print('HALO');
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
          context: homeContext,
          builder: (context) => PollPage(user: user, pollId: pollId, formKey: _formKey),
          barrierColor: Color(0x01000000));
      pollOpen = false;
    }
  }

  Widget createPages() {
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

    return Flexible(
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
          child: ListView(
            children: pollsList,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (polls == null) {
      return new Container();
    }

    if (!preventReload) {
      homeContext = context;
      preventReload = true;
      listViewBuilder = createPages();
    }

    return Scaffold(
      key: UniqueKey(),
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: appBar(),
      body: Column(
        children: [
          categoryTabs,
          polls.length > 0
              ? listViewBuilder
              : Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 1.4,
                    child: Center(child: Text('No polls found')),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: navBar(),
    );
  }
}

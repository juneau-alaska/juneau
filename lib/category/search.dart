import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juneau/comment/commentsPage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/categoryMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/methods/pollMethods.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/components/pollListPopover.dart';
import 'package:juneau/profile/profile.dart';
import 'package:rxdart/rxdart.dart';

List followingCategories;
List followingUsers;

class ResultWidget extends StatefulWidget {
  final user;
  final profileUser;
  final result;
  final type;
  final context;

  ResultWidget({
    Key key,
    @required this.user,
    this.profileUser,
    this.result,
    this.type,
    this.context,
  }) : super(key: key);

  @override
  _ResultWidgetState createState() => _ResultWidgetState();
}

class _ResultWidgetState extends State<ResultWidget> {
  var user;
  List pollObjects;
  BuildContext profileContext;

  bool pollOpen = false;
  bool preventReload = false;

  StreamController pollListController = StreamController.broadcast();
  StreamController parentController = new StreamController.broadcast();

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

  void updatedUserModel(updatedUser) {
    user = updatedUser;
    parentController.add({'dataType': 'user', 'data': user});
  }

  void openListView(name) async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
        selectedIndex: null,
        user: user,
        title: name,
        pollObjects: pollObjects,
        pollListController: pollListController,
        dismissPoll: dismissPoll,
        viewPoll: viewPoll,
        updatedUserModel: updatedUserModel,
        parentController: parentController,
        tag: null,
      );
    }));
  }

  Future fetchPollData(bool next, String type, String name) async {
    List polls;

    if (type == 'category') {
      polls = await pollMethods.getPollsFromCategory(name);

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
      }

      openListView(name);
    } else if (type == 'user') {
      var user = await userMethods.getUserByUsername(name);
      openProfile(context, user);
    }
  }

  @override
  void dispose() {
    pollListController.close();
    parentController.close();
    super.dispose();
  }

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var result = widget.result;

    List followingList;
    List followers;
    int followersLength;
    String followersLengthString;
    String name;
    String type = widget.type;

    bool isString = result is String;
    bool following = false;


    if (type == 'category') {
      followingList = followingCategories;
    } else if (type == 'user') {
      followingList = followingUsers;
    }

    if (!isString) {
      followers = result['followers'];
      followersLength = followers.length;
      followersLengthString = followersLength.toString();
      name = result['name'];
    } else {
      name = result;
    }

    if (followingList != null) {
      following = followingList.contains(name);
    }

    Widget nameWidget = GestureDetector(
      onTap: () async {
        fetchPollData(false, type, name);
      },
      child: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15.0,
        ),
      ),
    );

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: MediaQuery.of(context).size.width - 123,
            child: isString
                ? nameWidget
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nameWidget,
                      Text(
                        followersLength == 1
                            ? '$followersLengthString follower'
                            : '$followersLengthString followers',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
          ),
          RawMaterialButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              var updatedUser;

              if (type == 'category') {
                updatedUser = await categoryMethods.followCategory(name, following, followingList);
              } else if (type == 'user') {
                updatedUser = await userMethods.followUser(name, following, followingList);
              }

              if (updatedUser != null) {
                if (following) {
                  showAlert(context, 'Successfully unfollowed ' + type + ' "' + name + '"', true);
                } else {
                  showAlert(
                      context, 'Successfully followed ' + type + ' "' + name + '"', true);
                }

                setState(() {
                  if (type == 'category') {
                    followingCategories = updatedUser['followingCategories'];
                    followingList = followingCategories;
                  } else if (type == 'user') {
                    followingUsers = updatedUser['followingUsers'];
                    followingList = followingUsers;
                  }
                });
              } else {
                showAlert(context, 'Something went wrong, please try again');
              }
            },
            constraints: BoxConstraints(),
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            fillColor:
                following
                  ? Theme.of(context).backgroundColor
                  : Theme.of(context).primaryColor,
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              child: Text(
                following ? 'Unfollow' : 'Follow',
                style: TextStyle(
                  color:
                      following
                        ? Theme.of(context).buttonColor
                        : Theme.of(context).backgroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: following ? Theme.of(context).buttonColor : Theme.of(context).primaryColor, width: 0.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(20)),
          ),
        ],
      ),
    );
  }
}

Future<List> buildResults(user, List results, String type, BuildContext context) async {
  List<Widget> resultsWidgets = [];

  for (int i = 0; i < results.length; i++) {
    Widget resultWidget = new ResultWidget(
      user: user,
      result: results[i],
      type: type,
      context: context,
    );

    resultsWidgets.add(resultWidget);
  }

  return resultsWidgets;
}

class SearchedCategoriesList extends StatefulWidget {
  final user;
  final stream;

  SearchedCategoriesList({
    Key key,
    @required this.user,
    this.stream,
  }) : super(key: key);

  @override
  _SearchedCategoriesListState createState() => _SearchedCategoriesListState();
}

class _SearchedCategoriesListState extends State<SearchedCategoriesList> {
  List<Widget> categorySearchResults = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      categorySearchResults = await buildResults(widget.user, followingCategories, 'category', context);
      setState(() {});
    });

    widget.stream.listen((String text) async {
      text = text.toLowerCase();
      if (text == '') {
        categorySearchResults = await buildResults(widget.user, followingCategories, 'category', context);
      } else {
        List searchedCategories = await categoryMethods.searchCategories(text);

        categorySearchResults = await buildResults(widget.user, searchedCategories, 'category', context);
      }

      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categorySearchResults,
    );
  }
}

class SearchedUsersList extends StatefulWidget {
  final user;
  final stream;

  SearchedUsersList({
    Key key,
    @required this.user,
    this.stream,
  }) : super(key: key);

  @override
  _SearchedUsersListState createState() => _SearchedUsersListState();
}

class _SearchedUsersListState extends State<SearchedUsersList> {
  List<Widget> userSearchResults = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userSearchResults = await buildResults(widget.user, followingUsers, 'user', context);
      setState(() {});
    });

    widget.stream.listen((String text) async {
      text = text.toLowerCase();
      if (text == '') {
        userSearchResults = await buildResults(widget.user, followingUsers, 'user', context);
      } else {
        List searchedUsers = await userMethods.searchUsers(text);
        List users = [];

        for (int i = 0; i < searchedUsers.length; i++) {
          if (searchedUsers[i]['username'] != widget.user['username']) {
            users.add(searchedUsers[i]['username']);
          }
        }

        userSearchResults = await buildResults(widget.user, users, 'user', context);
      }

      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: userSearchResults,
    );
  }
}

class SearchPage extends StatefulWidget {
  final userId;

  SearchPage({
    Key key,
    @required this.userId,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  InputComponent searchBar;
  TextEditingController searchBarController;
  Widget categoriesList;
  Widget usersList;
  final streamController = StreamController<String>.broadcast();
  var user;

  @override
  void initState()  {
    Stream stream =
        streamController.stream.debounceTime(Duration(milliseconds: 250)).asBroadcastStream();

    searchBar = new InputComponent(
      hintText: "Find new categories and users to follow",
      contentPadding: EdgeInsets.fromLTRB(38.0, 7.0, 12.0, 15.0),
      maxLength: 30,
      inputFormatters: [FilteringTextInputFormatter.allow(new RegExp("[0-9A-Za-z]"))],
    );
    searchBarController = searchBar.controller;
    searchBarController.addListener(() => streamController.add(searchBarController.text.trim()));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      user = await userMethods.getUser(widget.userId);
      followingCategories = user['followingCategories'];
      followingUsers = user['followingUsers'];

      categoriesList = SearchedCategoriesList(
        user: user,
        stream: stream,
      );
      usersList = SearchedUsersList(
        user: user,
        stream: stream,
      );

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    searchBarController.dispose();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Stack(children: [
            searchBar,
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 6.5),
              child: Icon(Icons.search, color: Theme.of(context).hintColor, size: 19.0),
            ),
          ]),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListView(
              children: [
                Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: categoriesList,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'USERS',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: usersList,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/categoryMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:rxdart/rxdart.dart';

List followingCategories;
List followingUsers;

class ResultWidget extends StatefulWidget {
  final result;
  final type;
  final context;

  ResultWidget({
    Key key,
    @required this.result,
    this.type,
    this.context,
  }) : super(key: key);

  @override
  _ResultWidgetState createState() => _ResultWidgetState();
}

class _ResultWidgetState extends State<ResultWidget> {
  var result;
  String type;
  List followingList;

  @override
  void initState() {
    result = widget.result;
    type = widget.type;

    if (type == 'category') {
      followingList = followingCategories;
    } else if (type == 'user') {
      followingList = followingUsers;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List followers;
    int followersLength;
    String followersLengthString;
    String name;

    bool isString = result is String;
    bool following = false;

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

    Widget nameWidget = Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15.0,
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
                following ? Theme.of(context).buttonColor : Theme.of(context).backgroundColor,
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              child: Text(
                following ? 'Unfollow' : 'Follow',
                style: TextStyle(
                  color:
                      following ? Theme.of(context).backgroundColor : Theme.of(context).buttonColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: Theme.of(context).buttonColor, width: 0.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(20)),
          ),
        ],
      ),
    );
  }
}

Future<List> buildResults(List results, String type, BuildContext context) async {
  List<Widget> resultsWidgets = [];

  for (int i = 0; i < results.length; i++) {
    resultsWidgets.add(new ResultWidget(
      result: results[i],
      type: type,
      context: context,
    ));
  }

  return resultsWidgets;
}

class SearchedCategoriesList extends StatefulWidget {
  final stream;

  SearchedCategoriesList({
    Key key,
    @required this.stream,
  }) : super(key: key);

  @override
  _SearchedCategoriesListState createState() => _SearchedCategoriesListState();
}

class _SearchedCategoriesListState extends State<SearchedCategoriesList> {
  List<Widget> categorySearchResults = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      categorySearchResults = await buildResults(followingCategories, 'category', context);
      setState(() {});
    });

    widget.stream.listen((String text) async {
      text = text.toLowerCase();

      if (text == '') {
        categorySearchResults = await buildResults(followingCategories, 'category', context);
      } else {
        List searchedCategories = await categoryMethods.searchCategories(text);

        categorySearchResults = await buildResults(searchedCategories, 'category', context);
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
  final stream;

  SearchedUsersList({
    Key key,
    @required this.stream,
  }) : super(key: key);

  @override
  _SearchedUsersListState createState() => _SearchedUsersListState();
}

class _SearchedUsersListState extends State<SearchedUsersList> {
  List<Widget> userSearchResults = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userSearchResults = await buildResults(followingUsers, 'user', context);
      setState(() {});
    });

    widget.stream.listen((String text) async {
      text = text.toLowerCase();
      if (text == '') {
        userSearchResults = await buildResults(followingUsers, 'user', context);
      } else {
        List searchedUsers = await userMethods.searchUsers(text);
        List users = [];

        for (int i = 0; i < searchedUsers.length; i++) {
          users.add(searchedUsers[i]['username']);
        }

        userSearchResults = await buildResults(users, 'user', context);
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
  final user;

  SearchPage({
    Key key,
    @required this.user,
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

  @override
  void initState() {
    Stream stream =
        streamController.stream.debounceTime(Duration(milliseconds: 250)).asBroadcastStream();

    followingCategories = widget.user['followingCategories'];
    followingUsers = widget.user['followingUsers'];

    categoriesList = SearchedCategoriesList(
      stream: stream,
    );
    usersList = SearchedUsersList(
      stream: stream,
    );

    searchBar = new InputComponent(
      hintText: "Find new categories and users to follow",
      contentPadding: EdgeInsets.fromLTRB(38.0, 7.0, 12.0, 15.0),
      maxLength: 30,
      inputFormatters: [FilteringTextInputFormatter.allow(new RegExp("[0-9A-Za-z]"))],
    );
    searchBarController = searchBar.controller;
    searchBarController.addListener(() => streamController.add(searchBarController.text.trim()));

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
                Text(
                  'USERS',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
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

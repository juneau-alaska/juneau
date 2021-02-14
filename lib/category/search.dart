import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/categoryMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:rxdart/rxdart.dart';

Future<List<Widget>> buildResults(List results, List followingList, BuildContext context) async {
  List<Widget> resultsWidgets = [];

  for (int i = 0; i < results.length; i++) {
    var result = results[i];
    bool isString = result is String;
    bool following = followingList.contains(result);
    List followers;
    int followersLength;
    String followersLengthString;

    if (!isString) {
      followers = result['followers'];
      followersLength = followers.length;
      followersLengthString = followersLength.toString();
    }

    resultsWidgets.add(Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: MediaQuery.of(context).size.width - 123,
            child: isString
              ? Text(
              result,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15.0,
              ),
            )
              : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 15.0,
                  ),
                ),
                Text(
                  followersLength == 1 ? '$followersLengthString follower' : '$followersLengthString followers',
                  style: TextStyle(
                    fontSize: 13.0,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          RawMaterialButton(
            onPressed: () {},
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
    ));
  }

  return resultsWidgets;
}

class SearchedCategoriesList extends StatefulWidget {
  final stream;
  final followingCategories;

  SearchedCategoriesList({
    Key key,
    @required this.stream,
    this.followingCategories,
  }) : super(key: key);

  @override
  _SearchedCategoriesListState createState() => _SearchedCategoriesListState();
}

class _SearchedCategoriesListState extends State<SearchedCategoriesList> {
  List<Widget> searchResults = [];

  @override
  void initState() {
    super.initState();

    List followingCategories = widget.followingCategories;

    List followingResultsMemo;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      followingResultsMemo = await buildResults(followingCategories, followingCategories, context);
      searchResults = followingResultsMemo;
      setState(() {});
    });

    widget.stream.listen((String text) async {
      if (mounted) {
        text = text.toLowerCase();

        if (text == '') {
          searchResults = followingResultsMemo;
        } else {
          List searchedCategories = await categoryMethods.searchCategories(text);
          // List categories = [];
          //
          // for (int i=0; i<searchedCategories.length; i++) {
          //   categories.add(searchedCategories[i]['name']);
          // }

          searchResults = await buildResults(searchedCategories, followingCategories, context);
        }

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: searchResults,
    );
  }
}

class SearchedUsersList extends StatefulWidget {
  final stream;
  final followingUsers;

  SearchedUsersList({
    Key key,
    @required this.stream,
    this.followingUsers,
  }) : super(key: key);

  @override
  _SearchedUsersListState createState() => _SearchedUsersListState();
}

class _SearchedUsersListState extends State<SearchedUsersList> {
  List<Widget> searchResults = [];

  @override
  void initState() {
    super.initState();

    List followingUsers = widget.followingUsers;

    List followingResultsMemo;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      followingResultsMemo = await buildResults(followingUsers, followingUsers, context);
      searchResults = followingResultsMemo;
      setState(() {});
    });

    widget.stream.listen((String text) async {
      if (mounted) {
        text = text.toLowerCase();
        if (text == '') {
          searchResults = followingResultsMemo;
        } else {
          List searchedUsers = await userMethods.searchUsers(text);
          List users = [];

          for (int i = 0; i < searchedUsers.length; i++) {
            users.add(searchedUsers[i]['username']);
          }

          searchResults = await buildResults(users, followingUsers, context);
        }

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: searchResults,
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
    super.initState();

    var user = widget.user;
    List followingCategories = user['followingCategories'];
    List followingUsers = user['followingUsers'];

    Stream stream =
        streamController.stream.debounceTime(Duration(milliseconds: 250)).asBroadcastStream();

    categoriesList = SearchedCategoriesList(
      stream: stream,
      followingCategories: followingCategories,
    );
    usersList = SearchedUsersList(
      stream: stream,
      followingUsers: followingUsers,
    );

    searchBar = new InputComponent(
      hintText: "Find new categories and users to follow",
      contentPadding: EdgeInsets.fromLTRB(38.0, 7.0, 12.0, 15.0),
      maxLength: 30,
      inputFormatters: [FilteringTextInputFormatter.allow(new RegExp("[0-9A-Za-z]"))],
    );
    searchBarController = searchBar.controller;
    searchBarController.addListener(() => streamController.add(searchBarController.text.trim()));
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

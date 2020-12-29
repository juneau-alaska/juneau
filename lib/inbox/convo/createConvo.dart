import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/components/inputComponent.dart';

Future<List<Widget>> buildUsersList() {

}

class CreateConvoPage extends StatefulWidget {
  @override
  _CreateConvoPageState createState() => _CreateConvoPageState();
}

class _CreateConvoPageState extends State<CreateConvoPage> {
  InputComponent searchUserInput;
  TextEditingController searchUserController;

  final streamController = StreamController<String>();

  List<Widget> suggestedUsers = [];
  List<Widget> searchedUsers = [];

  List<Widget> buildSelectUsers(List users) {
    List<Widget> userCardWidgets = [];

    for (int i=0; i<users.length; i++) {
      var user = users[i];
      userCardWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Container(
            child: Row(
              children: [
                Text(
                  user['username'],
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ],
            ),
          ),
        ),
      );
    }

    return userCardWidgets;
  }

  @override
  void initState() {
    searchUserInput = new InputComponent(hintText: 'Search...');
    searchUserController = searchUserInput.controller;

    searchUserController.addListener(() => streamController.add(searchUserController.text.trim()));
    streamController.stream.debounceTime(Duration(milliseconds: 250)).listen((String text) async {
      if (mounted) {
        if (text == '') {
          searchedUsers = [];
        } else {
          List users = await userMethods.lookUpUsers(text);
          searchedUsers = buildSelectUsers(users);
        }

        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            )
          ),
          searchUserInput,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Text(
              'Suggested',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              )
            ),
          ),
          Flexible(
            child: ListView(
              children: searchedUsers.length > 0
              ? searchedUsers
              : suggestedUsers,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/alertComponent.dart';

Future<List> getCategories(String partialText, context) async {
  const url = 'http://localhost:4000/categories';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  var body = jsonEncode({'partialText': partialText});
  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return [];
  }
}

void createCategory(name, context) async {
  const url = 'http://localhost:4000/category';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  var body = jsonEncode({'name': name});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    Navigator.pop(context, name);
  } else {
    return showAlert(context, 'Something went wrong, please try again');
  }
}

class CategorySearchSelect extends StatefulWidget {
  @override
  _CategorySearchSelectState createState() => _CategorySearchSelectState();
}

class _CategorySearchSelectState extends State<CategorySearchSelect> {
  InputComponent searchBar;
  TextEditingController searchBarController;
  List<Widget> categoriesList = [Container()];
  final streamController = StreamController<String>();

  void buildCategoryOptions(text, context) async {
    if (context == null) return;

    if (text == "") {
      categoriesList[0] = Container();
    } else {
      categoriesList = [Container()];
      List categories = await getCategories(text, context);

      bool hasMatchingText = false;

      if (categories.length > 0) {
        for (var i = 0; i < categories.length; i++) {
          var category = categories[i], name = category['name'];

          if (name == text) {
            hasMatchingText = true;
          }

          categoriesList.add(GestureDetector(
              onTap: () {
                Navigator.pop(context, name);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name),
                        SizedBox(height: 1.0),
                        Text(category['followers'].length.toString() + ' following',
                            style: TextStyle(fontSize: 12.0, color: Theme.of(context).hintColor)),
                      ],
                    ),
                  ))));
        }
      }

      if (!hasMatchingText) {
        categoriesList[0] = GestureDetector(
            onTap: () {
              createCategory(text, context);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
                width: MediaQuery.of(context).size.width,
                child: Text(text,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.blue,
                    ))));
      }
    }
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    searchBar = new InputComponent(
      hintText: "Search",
      contentPadding: EdgeInsets.fromLTRB(35.0, 7.0, 12.0, 15.0),
    );
    searchBarController = searchBar.controller;
    searchBarController.addListener(() => streamController.add(searchBarController.text.trim()));
    streamController.stream.debounceTime(Duration(milliseconds: 250)).listen((text) {
      if (mounted) {
        buildCategoryOptions(text, context);
      }
    });
  }

  @override
  void dispose() {
    searchBarController.dispose();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Categories",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 100.0),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1.0,
          ),
          Stack(children: [
            searchBar,
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 7.0),
              child: Icon(Icons.search, color: Theme.of(context).hintColor, size: 19.0),
            ),
          ]),
          Expanded(
            child: SizedBox(
              height: 200.0,
              child: new ListView.builder(
                itemCount: categoriesList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: categoriesList[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

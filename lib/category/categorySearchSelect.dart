import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: throttle or debounce getCategories
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/alertComponent.dart';

void getCategories(String partialText, context) async {
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
    return showAlert(context, 'Something went wrong, please try again');
  }
}

void createCategory(name, context) async {
  Navigator.pop(context, name);
  return;
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
  List<Widget> categories;

  @override
  void initState() {
    searchBar = new InputComponent(
      hintText: "Search",
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      contentPadding: EdgeInsets.fromLTRB(35.0, 12.0, 12.0, 12.0),
    );
    searchBarController = searchBar.controller;
    categories = [Container()];

    searchBarController.addListener(() {
      setState(() {
        String text = searchBarController.text;
        categories[0] = GestureDetector(
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
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    searchBarController.dispose();
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
              padding: const EdgeInsets.only(left: 25.0, top: 21.0),
              child: Icon(Icons.search, color: Theme.of(context).hintColor, size: 20.0),
            ),
          ]),
          Expanded(
            child: SizedBox(
              height: 200.0,
              child: new ListView.builder(
                itemCount: categories.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: categories[index],
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

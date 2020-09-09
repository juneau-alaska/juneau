import 'package:flutter/material.dart';

import 'package:juneau/common/components/inputComponent.dart';

class CategorySearchSelect extends StatefulWidget {
  @override
  _CategorySearchSelectState createState() => _CategorySearchSelectState();
}

class _CategorySearchSelectState extends State<CategorySearchSelect> {
  InputComponent searchBar;
  TextEditingController searchBarController;
  List<String> categories;

  @override
  void initState() {
    searchBar = new InputComponent(
      hintText: "Search",
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      contentPadding: EdgeInsets.fromLTRB(35.0, 12.0, 12.0, 12.0),
    );
    searchBarController = searchBar.controller;
    categories = [];

    searchBarController.addListener(() {
      setState(() {
        String text = searchBarController.text;
        categories.add(text);
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
                    return new Text(categories[index]);
                  },
                ),
              ),
            ),
          ],
        ));
  }
}

import 'package:flutter/material.dart';

class PollMenu extends StatefulWidget {
  @override
  _PollMenuState createState() => _PollMenuState();
}

class _PollMenuState extends State<PollMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 40.0),
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.circular(8.0),
        color: Theme.of(context).backgroundColor,
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(10.0),
            decoration: new BoxDecoration(
              borderRadius: new BorderRadius.circular(8.0),
              color: Theme.of(context).highlightColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13.0),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
            ),
          )
        ],
      )
    );
  }
}

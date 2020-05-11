import 'package:flutter/material.dart';

final appBar = AppBar(
  leading: new Container(),
  backgroundColor: const Color(0xff121212),
  brightness: Brightness.dark,
  bottom: PreferredSize(
      child: Container(
        decoration: new BoxDecoration(
          border: Border(
            bottom: BorderSide(
                width: 0.5,
                color: const Color(0xff3B3B3B)
            ),
          ),
        ),
      ),
      preferredSize: Size.fromHeight(4.0)
  ),
);
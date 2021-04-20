import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry entry;

void showAlert(context, text, [bool success = false, bool blank = false]) {
  if (entry != null) {
    entry.remove();
  }

  Color color = success ? Colors.green : Colors.red;

  entry = OverlayEntry(builder: (BuildContext context) {
    return AlertComponent(text: text, color: color, blank: blank);
  });

  Navigator.of(context).overlay.insert(entry);
}

class AlertComponent extends StatefulWidget {
  final text;
  final color;
  final blank;

  AlertComponent({
    Key key,
    @required this.text,
    this.color,
    this.blank,
  }) : super(key: key);

  @override
  _AlertComponentState createState() => _AlertComponentState();
}

class _AlertComponentState extends State<AlertComponent> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<Offset> position;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    position = Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset.zero).animate(controller);

    controller.forward();
    new Future.delayed(const Duration(seconds: 2), () => controller.reverse());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: position,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 55.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 45,
              decoration: new BoxDecoration(
                color: widget.blank ? Theme.of(context).buttonColor : widget.color,
                borderRadius: new BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.0, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

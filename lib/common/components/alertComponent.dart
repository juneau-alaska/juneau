import 'package:flutter/material.dart';
import 'dart:async';

void showAlert(context, text) {
  Navigator.of(context)
    .overlay
    .insert(OverlayEntry(builder: (BuildContext context) {
    return AlertComponent(text: text);
  }));
}

class AlertComponent extends StatefulWidget {
  final text;

  AlertComponent({
    Key key,
    @required this.text,
  }) : super(key: key);

  @override
  _AlertComponentState createState() => _AlertComponentState();
}

class _AlertComponentState extends State<AlertComponent>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<Offset> position;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    position = Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset.zero)
        .animate(controller);

    controller.forward();
    new Future.delayed(const Duration(seconds: 2), () => controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: position,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 40,
              decoration: new BoxDecoration(
                borderRadius: new BorderRadius.circular(8.0),
                color: Colors.red,
              ),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.text,
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
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

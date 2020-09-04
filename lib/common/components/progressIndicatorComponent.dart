import 'package:flutter/material.dart';

class ProgressIndicatorComponent extends StatefulWidget {
  @override
  _ProgressIndicatorComponentState createState() =>
      _ProgressIndicatorComponentState();

  bool _isLoading = false;
  Function toggleLoading;
}

class _ProgressIndicatorComponentState
    extends State<ProgressIndicatorComponent> {
  @override
  Widget build(BuildContext context) {

    widget.toggleLoading = () {
      widget._isLoading = !widget._isLoading;
      setState(() {});
    };

    return Material(
      color: Colors.transparent,
      child: Center(child: widget._isLoading ? ProgressIndicatorComponent() : Container()),
    );
  }
}

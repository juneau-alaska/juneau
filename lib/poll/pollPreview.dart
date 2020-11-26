import 'package:flutter/material.dart';

class PollPreview extends StatefulWidget {
  final poll;

  PollPreview({Key key,
    @required this.poll,
  })
    : super(key: key);

  @override
  _PollPreviewState createState() => _PollPreviewState();
}

class _PollPreviewState extends State<PollPreview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Text(
        widget.poll['prompt'],
      ),
    );
  }
}

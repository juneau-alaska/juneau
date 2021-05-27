import 'package:flutter/material.dart';

import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/controllers/richTextController.dart';
import 'package:juneau/common/methods/commentMethods.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/numMethods.dart';
import 'package:juneau/profile/profile.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentWidget extends StatefulWidget {
  final comment;

  CommentWidget({
    Key key,
    @required this.comment,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  var comment;

  @override
  void initState() {
    comment = widget.comment;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Text(
        comment['comment'],
        style: TextStyle(
          fontSize: 15.0,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PollPreview extends StatefulWidget {
  final pollObject;

  PollPreview({
    Key key,
    @required this.pollObject,
  }) : super(key: key);

  @override
  _PollPreviewState createState() => _PollPreviewState();
}

class _PollPreviewState extends State<PollPreview> {
  List options;
  List images;
  Widget pollPreview;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      options = widget.pollObject['options'];
      images = widget.pollObject['images'];

      var firstOption = options[0];
      var highestVotedIndex = 0;
      int highestVoteCount = firstOption['votes'];

      for (var i = 1; i < options.length; i++) {
        var option = options[i];
        int votes = option['votes'];

        if (votes > highestVoteCount) {
          highestVoteCount = votes;
          highestVotedIndex = i;
        }
      }

      double size = MediaQuery.of(context).size.width / 3;

      setState(() {
        pollPreview = Container(
          width: size - 2,
          height: size - 2,
          child: Image.memory(
            images[highestVotedIndex],
            fit: BoxFit.cover,
            width: size - 2,
          ),
        );
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return pollPreview != null
        ? pollPreview
        : Container(
            color: Theme.of(context).hintColor,
          );
  }
}

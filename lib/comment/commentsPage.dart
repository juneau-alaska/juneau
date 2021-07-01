import 'dart:async';

import 'package:flutter/material.dart';
import 'package:juneau/comment/comment.dart';
import 'package:juneau/common/controllers/richTextController.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/methods/commentMethods.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

class BottomInput extends StatefulWidget {
  final pollId;
  final focusNode;
  final commentStreamController;
  final replyStreamController;
  final inputStreamController;

  BottomInput({
    Key key,
    @required this.pollId,
    this.focusNode,
    this.commentStreamController,
    this.replyStreamController,
    this.inputStreamController,
  }) : super(key: key);

  @override
  _BottomInputState createState() => _BottomInputState();
}

class _BottomInputState extends State<BottomInput> {
  bool isReply = false;
  bool preventSubmit = false;

  String pollId;
  String parentCommentId;
  String parentCommentUser;

  RichTextController inputController;

  void resetInput() {
    inputController.text = "";
    isReply = false;
    parentCommentId = null;
    parentCommentUser = null;
  }


  @override
  void initState() {
    pollId = widget.pollId;

    widget.inputStreamController.stream.listen((data) {
      setState(() {
        parentCommentId = data['parentCommentId'];
        parentCommentUser = data['parentCommentUser'];
        isReply = true;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inputController = RichTextController({
        RegExp(r"\B@[a-zA-Z0-9_.]+\b"): TextStyle(
          color: Theme
            .of(context)
            .highlightColor,
        ),
        RegExp(r"\B#[a-zA-Z0-9_.]+\b"): TextStyle(
          color: Theme
            .of(context)
            .highlightColor,
        ),
      });

      inputController.addListener(() {
        if (isReply && inputController.text == '') {
          resetInput();
          setState(() {});
        }
      });
    });

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        if (isReply && !visible) {
          setState(() {
            resetInput();
          });
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  OutlineInputBorder borderOutline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    borderSide: BorderSide(
      color: Colors.transparent,
      width: 0.5,
    ));

  @override
  Widget build(BuildContext context) {
    if (inputController != null) {
      inputController.text = parentCommentUser != null ? '@$parentCommentUser ' : '';
      inputController.selection =
        TextSelection.fromPosition(TextPosition(offset: inputController.text.length));
    }

    return Positioned(
      bottom: 0.0,
      child: Container(
        width: MediaQuery
          .of(context)
          .size
          .width,
        color: Theme
          .of(context)
          .backgroundColor,
        child: Column(
          children: [
            if (isReply)
              Container(
                width: MediaQuery
                  .of(context)
                  .size
                  .width,
                color: Theme
                  .of(context)
                  .dividerColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 13.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Replying to $parentCommentUser',
                        style: TextStyle(
                          color: Theme
                            .of(context)
                            .hintColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          resetInput();
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          size: 16.0,
                          color: Theme
                            .of(context)
                            .hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextField(
                      focusNode: widget.focusNode,
                      style: TextStyle(fontWeight: FontWeight.w300),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                        hintText: 'Add a comment',
                        hintStyle: TextStyle(
                          color: Theme
                            .of(context)
                            .hintColor,
                        ),
                        focusedBorder: borderOutline,
                        enabledBorder: borderOutline),
                      controller: inputController,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      String text = inputController.text;

                      if (text == '' || preventSubmit) {
                        return;
                      }

                      preventSubmit = true;

                      if (isReply) {
                        if (text != null || text
                          .replaceAll(new RegExp(r"\s+"), "")
                          .length > 0) {
                          var comment = await commentMethods.createComment(text, pollId, context,
                            parentCommentId: parentCommentId);

                          bool addedToComment = await commentMethods.updateCommentReplies(
                            parentCommentId, comment['_id'], context);
                          bool addedToPoll = await commentMethods.updatePollComments(
                            pollId, comment['_id'], context);

                          if (addedToPoll) {
                            widget.replyStreamController.add(comment);
                          } else {
                            showAlert(context, "Failed to reply to comment, please try again.");
                          }
                          resetInput();
                        }

                        widget.focusNode.unfocus();
                      } else {
                        if (text != null || text
                          .replaceAll(new RegExp(r"\s+"), "")
                          .length > 0) {
                          var comment = await commentMethods.createComment(text, pollId, context);
                          bool addedToPoll = await commentMethods.updatePollComments(
                            pollId, comment['_id'], context);

                          if (addedToPoll) {
                            // TODO: ADD COMMENT TO TOP OF LIST OF COMMENTS AND SCROLL UP AND HIGHLIGHT COMMENT
                            widget.commentStreamController.add(comment);
                            resetInput();
                          } else {
                            // TODO: ALERT FAILED TO SAVE COMMENT
                            showAlert(context, "Failed to post comment, please try again.");
                          }
                        }
                      }

                      preventSubmit = false;
                    },
                    child: Text(
                      'COMMENT',
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Theme
                          .of(context)
                          .highlightColor,
                        fontWeight: FontWeight.w700),
                    ))
                ],
              ),
            ),
          ],
        )),
    );
  }
}

class CommentsPage extends StatefulWidget {
  final user;
  final pollId;
  final formKey;

  CommentsPage({Key key, @required this.user, this.pollId, this.formKey}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _animation;

  var user;
  String pollId;

  List<Widget> commentWidgets = [];

  Widget bottomInput;
  FocusNode focusNode = FocusNode();

  StreamController commentStreamController = StreamController();
  StreamController replyStreamController = StreamController.broadcast();
  StreamController inputStreamController = StreamController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    user = widget.user;
    pollId = widget.pollId;

    bottomInput = BottomInput(
      pollId: pollId,
      focusNode: focusNode,
      inputStreamController: inputStreamController,
      commentStreamController: commentStreamController,
      replyStreamController: replyStreamController,
    );

    commentStreamController.stream.listen((comment) {
      setState(() {
        Widget commentWidget = CommentWidget(
          user: user,
          comment: comment,
          pollId: pollId,
          focusNode: focusNode,
          inputStreamController: inputStreamController,
          replyStreamController: replyStreamController,
        );
        commentWidgets.insert(0, commentWidget);

        if (_scrollController.offset != 0) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
      if (mounted) {
      }
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )
      ..forward();
    _animation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List pollComments = await commentMethods.getComments(pollId, context);

      for (var i = 0; i < pollComments.length; i++) {
        var comment = pollComments[i];
        Widget commentWidget = new CommentWidget(
          user: user,
          comment: comment,
          pollId: pollId,
          focusNode: focusNode,
          inputStreamController: inputStreamController,
          replyStreamController: replyStreamController,
        );
        commentWidgets.add(commentWidget);
      }

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    user = null;
    focusNode.dispose();
    commentStreamController.close();
    replyStreamController.close();
    inputStreamController.close();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void back() {
    focusNode.unfocus();
    _controller.reverse();
    commentStreamController.close();
    replyStreamController.close();
    inputStreamController.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        back();
      },
      child: Scaffold(
        key: widget.formKey,
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          SlideTransition(
            position: _animation,
            textDirection: TextDirection.rtl,
            child: Container(
              height: MediaQuery
                .of(context)
                .size
                .height,
              color: Theme
                .of(context)
                .backgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 0.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            back();
                          },
                          child: Icon(Icons.arrow_back, size: 25)),
                      ],
                    ),
                  ),
                  commentWidgets.length > 0
                    ? Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 60.0),
                        child: ListView(
                          children: commentWidgets,
                          controller: _scrollController,
                        ),
                      ),
                    ),
                  )
                    : Center(
                    child: Text('No comments'),
                  ),
                ],
              )),
          ),
          bottomInput,
        ]),
      ),
    );
  }
}

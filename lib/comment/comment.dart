import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';

import 'package:juneau/comment/commentsPage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/methods/commentMethods.dart';
import 'package:juneau/common/methods/categoryMethods.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/numberMethods.dart';
import 'package:juneau/common/methods/pollMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/components/pollListPopover.dart';
import 'package:juneau/profile/profile.dart';

class CommentWidget extends StatefulWidget {
  final user;
  final comment;
  final pollId;
  final focusNode;
  final inputStreamController;
  final replyStreamController;
  final isReply;

  CommentWidget({
    Key key,
    @required this.user,
    this.comment,
    this.pollId,
    this.focusNode,
    this.inputStreamController,
    this.replyStreamController,
    this.isReply,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> with AutomaticKeepAliveClientMixin<CommentWidget> {
  var comment;
  var creator;
  var user;
  var profilePhoto;

  String commentId;
  String time;
  bool pollOpen = false;
  bool preventReload = false;
  bool liked = false;
  bool repliesOpen = false;

  List replies;
  List<Widget> replyWidgets = [];
  List polls;
  List pollObjects = [];

  int likes = 0;
  int replyCount = 0;

  FocusNode focusNode;
  StreamController inputStreamController;
  StreamController pollListController = StreamController.broadcast();
  StreamController parentController = new StreamController.broadcast();

  void dismissPoll(index) {
    if (mounted) {
      setState(() {
        preventReload = false;
        pollObjects.removeAt(index);
        pollListController.add(pollObjects);
      });
    }
  }

  void viewPoll(String pollId) async {
    if (!pollOpen) {
      pollOpen = true;
      final _formKey = GlobalKey<FormState>();

      Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
        return CommentsPage(user: user, pollId: pollId, formKey: _formKey);
      }));

      pollOpen = false;
    }
  }

  void updatedUserModel(updatedUser) {
    user = updatedUser;
    parentController.add({'dataType': 'user', 'data': user});
  }

  void openListView(category) async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
        selectedIndex: null,
        user: user,
        title: category,
        pollObjects: pollObjects,
        pollListController: pollListController,
        dismissPoll: dismissPoll,
        viewPoll: viewPoll,
        updatedUserModel: updatedUserModel,
        parentController: parentController,
        tag: null,
      );
    }));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    user = widget.user;
    comment = widget.comment;
    focusNode = widget.focusNode;
    inputStreamController = widget.inputStreamController;

    commentId = comment['_id'];

    likes = comment['likes'];
    liked = user['likedComments'].contains(commentId);

    if (comment['replies'] != null) {
      replyCount = comment['replies'].length;
    }

    time = numberMethods.convertTime(comment['createdAt']);

    if (widget.isReply == null) {
      widget.replyStreamController.stream.listen((reply) {
        if (reply['parentCommentId'] == comment['_id']) {
          replyWidgets.insert(0, new CommentWidget(
            user: user,
            comment: reply,
            pollId: widget.pollId,
            focusNode: focusNode,
            inputStreamController: inputStreamController,
            isReply: true,
          ));
        }

        if (!mounted) {
          setState(() {});
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      creator = await userMethods.getUser(comment['createdBy']);

      String profilePhotoUrl = creator['profilePhoto'];
      if (profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    pollListController.close();
    parentController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    List<String> commentSplit = comment['comment'].split(' ');
    List<TextSpan> textChildren = [];

    RegExp regExpUsername = RegExp(r"\B@[a-zA-Z0-9]+\b");
    RegExp regExpCategory = RegExp(r"\B#[a-zA-Z0-9]+\b");

    if (creator != null) {
      textChildren.add(
        TextSpan(
          recognizer: TapGestureRecognizer()..onTap = () {
            openProfile(context, creator, user: user);
          },
          text: creator['username'] + ' ',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        )
      );
    }

    for (var i = 0; i < commentSplit.length; i++) {
      String text = commentSplit[i];

      if (regExpUsername.hasMatch(text)) {
        textChildren.add(
          TextSpan(
            recognizer: TapGestureRecognizer()..onTap = () async {
              String username = text.substring(1);
              var user = await userMethods.getUserByUsername(username);
              if (user != null) {
                openProfile(context, user);
              } else {
                showAlert(context, "User doesn't exist");
              }
            },
            text: text + ' ',
            style: TextStyle(
              color: Theme.of(context).highlightColor,
            ),
          ));
      } else if (regExpCategory.hasMatch(text)) {
        textChildren.add(
          TextSpan(
            recognizer: TapGestureRecognizer()..onTap = () async {
              String category = text.substring(1);
              polls = await pollMethods.getPollsFromCategory(category);
              if (polls != null) {
                for (int i = 0; i < polls.length; i++) {
                  var poll = polls[i];
                  pollObjects.add({
                    'index': i,
                    'poll': poll,
                  });
                }

                openListView(category);
              } else {
                showAlert(context, "Failed to retrieve polls in this category.");
              }
            },
            text: text + ' ',
            style: TextStyle(
              color: Theme.of(context).highlightColor,
            ),
          ));
      } else {
        textChildren.add(
          TextSpan(
            text: text + ' ',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      }
    }

    return Container(
      padding: widget.isReply == true ? EdgeInsets.only(top: 20.0) : EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3.0, right: 10.0),
            child: GestureDetector(
              child: profilePhoto != null
                ? Container(
                width: 32,
                height: 32,
                child: ClipOval(
                  child: Image.memory(
                    profilePhoto,
                    fit: BoxFit.cover,
                    width: 32.0,
                    height: 32.0,
                  ),
                ),
              )
                : CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('images/profile.png'),
              ),
              onTap: () {
                openProfile(context, creator);
              },
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: widget.isReply == true ? MediaQuery.of(context).size.width - 124 : MediaQuery.of(context).size.width - 82,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: RichText(
                    text: TextSpan(
                      text: '',
                      children: textChildren,
                    ),
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: GestureDetector(
                      onTap: () {
                        String parentCommentId = comment['parentCommentId'] == null ? comment['_id'] : comment['parentCommentId'];
                        inputStreamController.add({'parentCommentId': parentCommentId, 'parentCommentUser': creator['username']});
                        focusNode.nextFocus();
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      var updatedComment = await commentMethods.likeComment(commentId, liked);
                      var updatedUser = await userMethods.updateUserLikedComments(commentId, liked);
                      if (updatedComment != null) {
                        comment = updatedComment;
                      }
                      if (updatedUser != null) {
                        user = updatedUser;
                      }
                      liked = user['likedComments'].contains(commentId);
                      likes = comment['likes'];
                      setState(() {});
                    },
                    child: Text(
                      likes == 0 ? 'Like' : likes == 1 ? '1 Like' : '$likes Likes',
                      style: TextStyle(
                        fontSize: 12,
                        color: liked ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
                        fontWeight: liked ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (!repliesOpen && replyCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      replies = await commentMethods.getComments(widget.pollId, context, parentCommentId: commentId);

                      for (var i = 0; i < replies.length; i++) {
                        var comment = replies[i];
                        Widget commentWidget = new CommentWidget(
                          user: user,
                          comment: comment,
                          pollId: widget.pollId,
                          focusNode: focusNode,
                          inputStreamController: inputStreamController,
                          isReply: true,
                        );
                        replyWidgets.add(commentWidget);
                      }

                      repliesOpen = true;
                      setState(() {});
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 3.0, bottom: 1.0),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        Text(
                          replyCount == 1 ? 'Show $replyCount reply' : 'Show $replyCount replies',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: replyWidgets,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

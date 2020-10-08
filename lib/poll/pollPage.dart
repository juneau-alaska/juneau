import 'package:flutter/material.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:keyboard_visibility/keyboard_visibility.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/common/components/alertComponent.dart';

List<Widget> commentWidgets;
List commentList;
FocusNode focusNode;
String pollId;

StreamController commentStreamController;
StreamController replyStreamController;
StreamController inputStreamController;

Map<String, List<Widget>> commentReplyWidgets = {};
Map<String, bool> commentRepliesOpened = {};

Future<List> fetchComments(String parentId, context) async {
  String url = 'http://localhost:4000/comments/' + parentId;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  } else {
    // TODO: Remove and use inline text
    showAlert(context, 'Something went wrong, please try again');
    return [];
  }
}

Future createComment(String comment, String parentId, context) async {
  const url = 'http://localhost:4000/comment';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'),
    userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode({'content': comment, 'parent': parentId, 'createdBy': userId});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body),
      id = jsonResponse['_id'];

    commentReplyWidgets[id] = [];
    commentRepliesOpened[id] = false;

    return jsonResponse;
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return null;
  }
}

Future<bool> updateCommentReplies(commentId, replyId, context) async {
  String url = 'http://localhost:4000/comment/' + commentId;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url, headers: headers),
    body;

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body),
      replies = jsonResponse['replies'];

    replies.add(replyId);

    body = jsonEncode({'replies': replies});

    response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return true;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return false;
    }
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return false;
  }
}

Future<bool> updatePollComments(commentId, context) async {
  String url = 'http://localhost:4000/poll/' + pollId;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body),
      comments = jsonResponse['comments'];

    comments.add(commentId);

    var body = jsonEncode({'comments': comments});

    response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return true;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return false;
    }
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return false;
  }
}

Future getCreatedByUser(String createdById) async {
  String url = 'http://localhost:4000/user/' + createdById;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  } else {
    return null;
  }
}

Future<List> buildComments(comments, context) async {
  List<Widget> widgets = [];
  for (var i = 0; i < comments.length; i++) {
    var comment = comments[i];

    if (commentReplyWidgets[comment['_id']] == null) {
      commentReplyWidgets[comment['_id']] = [];
    }

    Widget commentWidget = await createCommentWidget(comment, context);
    widgets.add(commentWidget);
  }
  return widgets;
}

Future<Widget> createCommentWidget(comment, context) async {
  var createdBy = comment['createdBy'],
    creator = await getCreatedByUser(createdBy),
    replies = comment['replies'],
    numReplies = replies.length,
    id = comment['_id'];

  List<Widget> replyWidgets = commentReplyWidgets[id];
  bool repliesOpened = commentRepliesOpened[id] != null ? commentRepliesOpened[id] : false;

  DateTime createdAt = DateTime.parse(comment['createdAt']);
  String time = timeago.format(createdAt, locale: 'en_short');

  return Container(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              child: Text(
                creator['username'],
                style: TextStyle(
                  color: Theme
                    .of(context)
                    .hintColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300),
              ),
              onTap: () {
                print(creator['email']);
              }),
            Padding(
              padding: const EdgeInsets.only(left: 3.0, right: 1.0),
              child: Text('•',
                style: TextStyle(
                  color: Theme
                    .of(context)
                    .hintColor,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700)),
            ),
            Text(
              time,
              style: TextStyle(
                color: Theme
                  .of(context)
                  .hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w300,
                wordSpacing: -4.0,
              ),
            ),
          ]),
          SizedBox(
            height: 1.0,
          ),
          Text(comment['content'], style: TextStyle(fontSize: 16.0)),
          SizedBox(
            height: 3.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  inputStreamController
                    .add({'hint': 'Replying to ' + creator['username'], 'commentId': id});
                  focusNode.requestFocus();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.reply, size: 20.0, color: Theme
                      .of(context)
                      .hintColor),
                    SizedBox(width: 1.0),
                    Text(
                      'Reply',
                      style: TextStyle(fontSize: 15.0, color: Theme
                        .of(context)
                        .hintColor),
                    ),
                  ],
                ),
              ),
            ]),
          replies.length > 0 && !repliesOpened
            ? Center(
            child: GestureDetector(
              onTap: () async {
                List fetchedReplies = await fetchComments(id, context);
                List fetchedReplyWidgets = await buildComments(fetchedReplies, context);
                commentReplyWidgets[id] = replyWidgets + fetchedReplyWidgets;
                commentRepliesOpened[id] = true;
                replyStreamController.add(true);
              },
              child: Text(
                numReplies == 1 ? '1 reply' : '$numReplies replies',
                style: TextStyle(fontSize: 15.0, color: Theme
                  .of(context)
                  .hintColor),
              ),
            ),
          ) : Container(),
          replyWidgets.length > 0 ?
          Container(
            child: Column(children: replyWidgets),
          ) : Container()
        ],
      ),
    ),
  );
}

class CommentsWidget extends StatefulWidget {
  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      commentList = await fetchComments(pollId, context);
      commentWidgets = await buildComments(commentList, context);
      setState(() {});
    });
    super.initState();
    commentReplyWidgets = {};
    commentStreamController = StreamController();
    commentStreamController.stream.listen((widget) {
      setState(() {
        commentWidgets.insert(0, widget);
      });
    });
    replyStreamController = StreamController();
    replyStreamController.stream.listen((reply) async {
      commentWidgets = await buildComments(commentList, context);
      setState(() {});
    });
  }

  @override
  void dispose() {
    commentStreamController.close();
    replyStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return commentList != null
      ? Container(
      width: MediaQuery
        .of(context)
        .size
        .width,
      color: Theme
        .of(context)
        .backgroundColor,
      child: Column(
        children: commentWidgets != null && commentWidgets.length > 0
          ? commentWidgets
          : [
          Center(
            child: Text(
              commentList.length == 0 ? 'No comments' : 'Failed to retrieve comments',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w300,
                color: Theme
                  .of(context)
                  .hintColor,
              )),
          ),
        ],
      ),
    )
      : Container(
      height: 100.0,
      width: MediaQuery
        .of(context)
        .size
        .width,
      child: Center(child: CircularProgressIndicator()));
  }
}

class BottomInput extends StatefulWidget {
  @override
  _BottomInputState createState() => _BottomInputState();
}

class _BottomInputState extends State<BottomInput> {
  TextEditingController inputController = TextEditingController();
  String hintText = 'Add a comment';
  bool isReply = false;
  String parentId;

  void resetInput() {
    inputController.text = "";
    hintText = 'Add a comment';
    isReply = false;
    parentId = null;
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    inputStreamController = StreamController();
    inputStreamController.stream.listen((obj) {
      setState(() {
        parentId = obj['commentId'];
        hintText = obj['hint'];
        isReply = true;
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
  }

  @override
  void dispose() {
    focusNode.dispose();
    inputStreamController.close();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: TextField(
                  focusNode: focusNode,
                  style: TextStyle(fontWeight: FontWeight.w300),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Theme
                        .of(context)
                        .hintColor, fontWeight: FontWeight.w300),
                    focusedBorder: borderOutline,
                    enabledBorder: borderOutline),
                  controller: inputController,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  String text = inputController.text;

                  if (isReply) {
                    if (text != null || text
                      .replaceAll(new RegExp(r"\s+"), "")
                      .length > 0) {
                      var comment = await createComment(text, parentId, context);
                      bool addedToComment =
                      await updateCommentReplies(parentId, comment['_id'], context);

                      if (addedToComment) {
                        Widget commentWidget = await createCommentWidget(comment, context);
                        commentReplyWidgets[parentId].add(commentWidget);
                        replyStreamController.add(true);
                      }
                    }
                    focusNode.unfocus();
                  } else {
                    if (text != null || text
                      .replaceAll(new RegExp(r"\s+"), "")
                      .length > 0) {
                      var comment = await createComment(text, pollId, context);
                      bool addedToPoll = await updatePollComments(comment['_id'], context);

                      if (addedToPoll) {
                        Widget commentWidget = await createCommentWidget(comment, context);
                        commentList.insert(0, comment);
                        commentStreamController.add(commentWidget);
                        inputController.text = "";
                      }
                    }
                  }
                },
                child: Text(
                  'COMMENT',
                  style: TextStyle(
                    fontSize: 15.0, color: Colors.blueAccent, fontWeight: FontWeight.w700),
                ))
            ],
          ),
        )),
    );
  }
}

class PollPage extends StatefulWidget {
  final pollWidget;
  final pollId;
  final formKey;

  PollPage({Key key, @required this.pollWidget, this.pollId, this.formKey}) : super(key: key);

  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    pollId = widget.pollId;
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
  }

  @override
  void dispose() {
    commentList = null;
    commentWidgets = null;
    _controller.dispose();
    super.dispose();
  }

  void back() {
    focusNode.unfocus();
    _controller.reverse();
    commentStreamController.close();
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
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  widget.pollWidget,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: CommentsWidget(),
                  ),
                ],
              )),
          ),
          BottomInput(),
        ]),
      ),
    );
  }
}

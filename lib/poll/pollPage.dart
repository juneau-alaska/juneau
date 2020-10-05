import 'package:flutter/material.dart';

import 'package:timeago/timeago.dart' as timeago;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:juneau/common/components/alertComponent.dart';

List<Widget> commentWidgets;
List commentList;

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

class CommentWidget extends StatefulWidget {
  final pollId;

  CommentWidget({Key key, @required this.pollId}) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  void fetchComments(String parentId) async {
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
      commentList = jsonResponse;
      buildComments();
    } else {
      // TODO: Remove and use inline text
      showAlert(context, 'Something went wrong, please try again');
    }
  }

  void buildComments() async {
    if (commentWidgets == null) {
      commentWidgets = [];
      for (var i = 0; i < commentList.length; i++) {
        var comment = commentList[i],
            createdBy = comment['createdBy'],
            creator = await getCreatedByUser(createdBy);

        DateTime createdAt = DateTime.parse(comment['createdAt']);
        String time = timeago.format(createdAt, locale: 'en_short');

        commentWidgets.add(
          Container(
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
                              color: Theme.of(context).hintColor,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w300),
                        ),
                        onTap: () {
                          print(creator['email']);
                        }),
                    Padding(
                      padding: const EdgeInsets.only(left: 3.0, right: 1.0),
                      child: Text('•',
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        wordSpacing: -4.0,
                      ),
                    ),
                  ]),
                  SizedBox(
                    height: 3.0,
                  ),
                  Text(comment['content']),
                  Row(),
                ],
              ),
            ),
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: FIX, CAN'T KEEP FETCHING
    if (commentList == null) {
      fetchComments(widget.pollId);
    }

    return commentList != null
        ? Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).backgroundColor,
            child: Column(
              children: commentWidgets != null
                  ? commentWidgets
                  : [
                      Container(
                          child: Center(
                        child: Text(
                            commentList.length > 0 ? 'Failed to retrieve comments' : 'No comments',
                            style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300)),
                      )),
                    ],
            ),
          )
        : Container(
            height: 100.0,
            width: MediaQuery.of(context).size.width,
            child: Center(child: CircularProgressIndicator()));
  }
}

class PollPage extends StatefulWidget {
  final pollWidget;
  final pollId;

  PollPage({Key key, @required this.pollWidget, this.pollId}) : super(key: key);

  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> with SingleTickerProviderStateMixin {
  TextEditingController inputController = TextEditingController();
  AnimationController _controller;
  Animation<Offset> _animation;

  Future postComment(String comment, String parentId) async {
    const url = 'http://localhost:4000/comment';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token'), userId = prefs.getString('userId');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'content': comment, 'parent': parentId, 'createdBy': userId});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return null;
    }
  }

//  void updateCommentReplies() async {
//    const url = 'http://localhost:4000/comment';
//
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    var token = prefs.getString('token');
//
//    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};
//
//    var response = await http.get(url + '/' + commentId, headers: headers);
//
//    if (response.statusCode == 200) {
//      var jsonResponse = jsonDecode(response.body),
//          replies = jsonResponse['replies'],
//          body = jsonEncode({replies: replies});
//
//      response = await http.put(url, headers: headers, body: body);
//
//      if (response.statusCode == 200) {
//        // TODO: POST REPLY
//      } else {
//        showAlert(context, 'Something went wrong, please try again');
//      }
//    } else {
//      showAlert(context, 'Something went wrong, please try again');
//    }
//  }

  Future<bool> updatePollComments(commentId) async {
    String url = 'http://localhost:4000/poll/' + widget.pollId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body)[0], comments = jsonResponse['comments'];

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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _animation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));

    // TODO: FETCH COMMENTS USING POLL ID, ADD A LOADING CIRCLE IN COMMENTS SECTION - SHOW COMMENTS ON SUCCESS OR SHOW ERROR ON ERROR
//    WidgetsBinding.instance.addPostFrameCallback((_) => fetchComments(widget.pollId));
  }

  @override
  void dispose() {
    inputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void back() {
    _controller.reverse();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borderOutline = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.transparent,
          width: 0.5,
        ));

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        print(direction);
        back();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SlideTransition(
          position: _animation,
          textDirection: TextDirection.rtl,
          child: Container(
              height: MediaQuery.of(context).size.height,
              color: Theme.of(context).backgroundColor,
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
                  CommentWidget(pollId: widget.pollId),
                ],
              )),
        ),
        bottomNavigationBar: Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextField(
                      style: TextStyle(fontWeight: FontWeight.w300),
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                          hintText: 'Add a comment',
                          hintStyle: TextStyle(
                              color: Theme.of(context).hintColor, fontWeight: FontWeight.w300),
                          focusedBorder: borderOutline,
                          enabledBorder: borderOutline),
                      controller: inputController,
                    ),
                  ),
                  GestureDetector(
                      onTap: () async {
                        String text = inputController.text;
                        if (text != null || text.replaceAll(new RegExp(r"\s+"), "").length > 0) {
                          var comment = await postComment(text, widget.pollId);
                          bool addedToPoll = await updatePollComments(comment['_id']);
                          if (addedToPoll) {
                            // TODO: add new comment to comments list - controller detect change and create single widget and add to widget list and rerender?
                            inputController.text = "";
                          }
                        }
                      },
                      child: Text(
                        'SUBMIT',
                        style: TextStyle(
                            fontSize: 15.0, color: Colors.blueAccent, fontWeight: FontWeight.w700),
                      ))
                ],
              ),
            )),
      ),
    );
  }
}

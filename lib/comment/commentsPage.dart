import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/colors.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/controllers/richTextController.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/numMethods.dart';
import 'package:juneau/profile/profile.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

var currentUser;
List<Widget> commentWidgets;
List commentList;
FocusNode focusNode;
String pollId;

StreamController commentStreamController;
StreamController rebuildStreamController;
StreamController inputStreamController;

Map<String, List> commentReplies = {};
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
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode({'content': comment, 'parent': parentId, 'createdBy': userId});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), id = jsonResponse['_id'];

    commentReplies[id] = [];
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

  var response = await http.get(url, headers: headers), body;

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), replies = jsonResponse['replies'];

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
    var jsonResponse = jsonDecode(response.body), comments = jsonResponse['comments'];

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

Future getUser(String username) async {
  String url = 'http://localhost:4000/user/username/' + username;

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

Future<bool> updateUserLikedComments(String commentId, bool liked) async {
  String url = 'http://localhost:4000/user/';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url + userId, headers: headers), body;

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), likedComments = jsonResponse['likedComments'];

    if (liked && likedComments.contains(commentId)) {
      likedComments.remove(commentId);
    } else {
      likedComments.add(commentId);
    }

    jsonResponse['likedComments'] = likedComments;

    body = jsonEncode(jsonResponse);

    response = await http.put(url + userId, headers: headers, body: body);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

Future<bool> likeComment(String commentId, bool liked) async {
  String url = 'http://localhost:4000/comment/like/' + commentId;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode({'liked': liked});

  var response = await http.put(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    bool updated = await updateUserLikedComments(commentId, liked);
    return updated;
  } else {
    return false;
  }
}

Future<List> buildComments(comments, context, {isReply = false}) async {
  List<Widget> widgets = [];

  for (var i = 0; i < comments.length; i++) {
    var comment = comments[i], id = comment['_id'];

    if (commentReplies[id] == null) {
      commentReplies[id] = [];
    }

    if (commentReplyWidgets[id] == null) {
      commentReplyWidgets[id] = [];
    }

    Widget commentWidget = await createCommentWidget(comment, context, nested: isReply);
    widgets.add(commentWidget);
  }

  return widgets;
}

Future<Widget> createCommentWidget(comment, context, {nested = false}) async {
  var createdBy = comment['createdBy'],
      creator = await getCreatedByUser(createdBy),
      replies = comment['replies'],
      numReplies = replies.length,
      id = comment['_id'],
      likes = comment['likes'],
      liked = currentUser['likedComments'].contains(id),
      parentId = comment['parent'];

  List<Widget> replyWidgets = commentReplyWidgets[id];
  bool repliesOpened = commentRepliesOpened[id] != null ? commentRepliesOpened[id] : false;

  DateTime createdAt = DateTime.parse(comment['createdAt']);
  String time = timeago.format(createdAt, locale: 'en_short').replaceAll(new RegExp(r'~'), '');

  List<String> contentSplit = comment['content'].split(' ');
  List<Widget> textChildren = [];

  RegExp regExp = RegExp(r"\B@[a-zA-Z0-9]+\b");

  for (var i = 0; i < contentSplit.length; i++) {
    String text = contentSplit[i];

    if (regExp.hasMatch(text)) {
      textChildren.add(GestureDetector(
        onTap: () async {
          String username = text.substring(1);
          var user = await getUser(username);
          if (user != null) {
            openProfile(context, user);
          } else {
            showAlert(context, "User doesn't exist");
          }
        },
        child: Text(text + ' ',
            style: TextStyle(
              color: Theme.of(context).highlightColor,
              fontSize: 15.0,
            )),
      ));
    } else {
      textChildren.add(Text(text + ' ', style: TextStyle(fontSize: 15.0)));
    }
  }

  EdgeInsets padding = nested
      ? EdgeInsets.fromLTRB(40.0, 5.0, 15.0, 5.0)
      : EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 5.0);

  double mediaWidth = MediaQuery.of(context).size.width;

  var profilePhoto;
  String profilePhotoUrl = creator['profilePhoto'];
  if (profilePhotoUrl != null) {
    profilePhoto = await imageMethods.getImage(profilePhotoUrl);
  }

  Widget commentContainer = Container(
    color: Theme.of(context).backgroundColor,
    child: Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: GestureDetector(
                      child: profilePhoto != null
                          ? Container(
                              width: 19,
                              height: 19,
                              child: ClipOval(
                                child: Image.memory(
                                  profilePhoto,
                                  fit: BoxFit.cover,
                                  width: 19.0,
                                  height: 19.0,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 9.5,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage('images/profile.png'),
                            ),
                      onTap: () {
                        openProfile(context, creator);
                      },
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        child: Text(
                          creator['username'],
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          openProfile(context, creator);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2.0, 1.0, 2.0, 0.0),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0.5),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            wordSpacing: -3.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 3.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: Container(
                  width: nested ? mediaWidth - 110 : mediaWidth - 75,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    children: textChildren,
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () async {
                  bool commentLiked = await likeComment(id, liked);
                  if (commentLiked) {
                    if (liked) {
                      comment['likes'] = likes - 1;
                      currentUser['likedComments'].remove(id);
                    } else {
                      comment['likes'] = likes + 1;
                      currentUser['likedComments'].add(id);
                    }

                    List list;
                    if (parentId == pollId) {
                      list = commentList;
                    } else {
                      list = commentReplies[parentId];
                    }
                    rebuildStreamController.add({'list': list, 'parentId': parentId});
                  }
                },
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 15.0,
                  color: liked ? Theme.of(context).accentColor : Theme.of(context).hintColor,
                ),
              ),
              SizedBox(height: 2.5),
              Text(likes == 0 ? '' : numberMethods.shortenNum(likes),
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(context).hintColor,
                  ))
            ],
          ),
        ],
      ),
    ),
  );

  return GestureDetector(
    onTap: () {
      if (nested) {
        inputStreamController.add({'commentId': parentId, 'repliedToUser': creator['username']});
      } else {
        inputStreamController.add({'commentId': id});
      }
      focusNode.requestFocus();
    },
    child: Column(
      children: [
        createdBy == currentUser['_id']
            ? SwipeActionCell(
                key: UniqueKey(),
                performsFirstActionWithFullSwipe: true,
                trailingActions: [
                  SwipeAction(
                    title: "delete",
                    nestedAction: SwipeNestedAction(title: "delete"),
                    onTap: (CompletionHandler handler) async {
                      comment['content'] = 'deleted';
                      rebuildStreamController.add({'list': commentList});
                    },
                    color: Colors.red,
                  ),
                ],
                child: commentContainer,
              )
            : commentContainer,
        replyWidgets.length > 0 && repliesOpened
            ? Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: replyWidgets),
              )
            : Container(),
        !nested
            ? replies.length > 0
                ? !repliesOpened
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(40.0, 0.0, 15.0, 5.0),
                        child: GestureDetector(
                          onTap: () async {
                            openReplies(id, context);
                          },
                          child: Row(
                            children: [
                              Text(
                                'View replies ($numReplies)',
                                style:
                                    TextStyle(fontSize: 13.0, color: Theme.of(context).hintColor),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 20.0,
                                color: Theme.of(context).hintColor,
                              )
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(40.0, 0.0, 15.0, 5.0),
                        child: GestureDetector(
                          onTap: () async {
                            commentRepliesOpened[id] = null;
                            rebuildStreamController.add({'list': commentList});
                          },
                          child: Row(
                            children: [
                              Text(
                                'Hide replies',
                                style:
                                    TextStyle(fontSize: 13.0, color: Theme.of(context).hintColor),
                              ),
                              Icon(
                                Icons.keyboard_arrow_up,
                                size: 20.0,
                                color: Theme.of(context).hintColor,
                              )
                            ],
                          ),
                        ),
                      )
                : Container()
            : Container(),
      ],
    ),
  );
}

void openReplies(String id, context) async {
  if (commentReplies[id].length == 0) {
    List fetchedReplies = await fetchComments(id, context);
    commentReplies[id] = fetchedReplies;
    List fetchedReplyWidgets = await buildComments(fetchedReplies, context, isReply: true);
    commentReplyWidgets[id] = commentReplyWidgets[id] + fetchedReplyWidgets;
  }
  commentRepliesOpened[id] = true;
  rebuildStreamController.add({'list': commentList});
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

    commentReplies = {};
    commentReplyWidgets = {};
    commentRepliesOpened = {};

    commentStreamController = StreamController();
    commentStreamController.stream.listen((obj) async {
      Widget widget = obj['widget'];
      if (widget != null) {
        setState(() {
          commentWidgets.insert(0, widget);
        });
      }
    });

    rebuildStreamController = StreamController();
    rebuildStreamController.stream.listen((obj) async {
      List list = obj['list'];
      String parentId = obj['parentId'];

      if (list != null && list.length > 0) {
        if (parentId != null && parentId != pollId) {
          commentReplyWidgets[parentId] = await buildComments(list, context, isReply: true);
        }
        commentWidgets = await buildComments(commentList, context);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    commentStreamController.close();
    rebuildStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return commentList != null
        ? Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).backgroundColor,
            child: Column(
              children: commentWidgets != null && commentWidgets.length > 0
                  ? commentWidgets
                  : [
                      Center(
                        child: Text(
                          commentList.length == 0 ? 'No comments' : 'Failed to retrieve comments',
                          style: TextStyle(
                            fontSize: 15.0,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ],
            ),
          )
        : Container(
            height: 100.0,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}

class BottomInput extends StatefulWidget {
  @override
  _BottomInputState createState() => _BottomInputState();
}

class _BottomInputState extends State<BottomInput> {
  RichTextController inputController = RichTextController({
    RegExp(r"\B@[a-zA-Z0-9_.]+\b"): TextStyle(
      color: customColors.blue,
    ),
  });
  bool isReply = false;
  String parentId;
  String repliedToUser;
  bool preventSubmit = false;

  void resetInput() {
    inputController.text = "";
    isReply = false;
    parentId = null;
  }

  @override
  void initState() {
    focusNode = FocusNode();
    inputStreamController = StreamController();
    inputStreamController.stream.listen((obj) {
      setState(() {
        parentId = obj['commentId'];
        repliedToUser = obj['repliedToUser'];
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

    super.initState();
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
    inputController.text = repliedToUser != null ? '@$repliedToUser ' : '';
    inputController.selection =
        TextSelection.fromPosition(TextPosition(offset: inputController.text.length));

    return Positioned(
      bottom: 0.0,
      child: Container(
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).backgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 30.0),
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
                        hintText: 'Add a comment',
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
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
                        openReplies(parentId, context);

                        if (text != null || text.replaceAll(new RegExp(r"\s+"), "").length > 0) {
                          var comment = await createComment(text, parentId, context);
                          commentReplies[parentId].add(comment);

                          bool addedToComment =
                              await updateCommentReplies(parentId, comment['_id'], context);

                          if (addedToComment) {
                            Widget commentWidget =
                                await createCommentWidget(comment, context, nested: true);
                            commentReplyWidgets[parentId].insert(0, commentWidget);
                            rebuildStreamController.add({'list': commentList});
                            resetInput();
                          }
                        }
                        focusNode.unfocus();
                      } else {
                        if (text != null || text.replaceAll(new RegExp(r"\s+"), "").length > 0) {
                          var comment = await createComment(text, pollId, context);
                          bool addedToPoll = await updatePollComments(comment['_id'], context);

                          if (addedToPoll) {
                            Widget commentWidget = await createCommentWidget(comment, context);
                            commentList.insert(0, comment);
                            commentStreamController.add({'widget': commentWidget});
                            resetInput();
                          }
                        }
                      }

                      preventSubmit = false;
                    },
                    child: Text(
                      'COMMENT',
                      style: TextStyle(
                          fontSize: 15.0,
                          color: Theme.of(context).highlightColor,
                          fontWeight: FontWeight.w700),
                    ))
              ],
            ),
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

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    pollId = widget.pollId;
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
  }

  @override
  void dispose() {
    currentUser = null;
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
                height: MediaQuery.of(context).size.height,
                color: Theme.of(context).backgroundColor,
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
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 60.0),
                              child: CommentsWidget(),
                            ),
                          ],
                        ),
                      ),
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

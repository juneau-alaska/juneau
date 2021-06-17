import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentMethods {
  Future<List> getComments(String pollId, context, {String parentCommentId}) async {
    String url = API_URL + 'comments';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'pollId': pollId, 'parentCommentId': parentCommentId});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var comments = jsonDecode(response.body);
      return comments;
    } else {
      // TODO: Remove and use inline text
      showAlert(context, 'Failed to retrieve comments.');
      return [];
    }
  }

  Future createComment(String comment, String pollId, context, {String parentCommentId}) async {
    String url = API_URL + 'comment';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token'), userId = prefs.getString('userId');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body;

    if (parentCommentId != null) {
      body = jsonEncode({'comment': comment, 'pollId': pollId, 'parentCommentId': parentCommentId, 'createdBy': userId});
    } else {
      body = jsonEncode({'comment': comment, 'pollId': pollId, 'createdBy': userId});
    }

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var comment = jsonDecode(response.body); //,
          // id = jsonResponse['_id'];

      // commentReplies[id] = [];
      // commentReplyWidgets[id] = [];
      // commentRepliesOpened[id] = false;

      return comment;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return null;
    }
  }

  Future<bool> updateCommentReplies(commentId, replyId, context) async {
    String url = API_URL + 'comment/' + commentId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url, headers: headers), body;

    if (response.statusCode == 200) {
      var comment = jsonDecode(response.body),
          replies = comment['replies'];

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

  Future<bool> updatePollComments(pollId, commentId, context) async {
    String url = API_URL + 'poll/' + pollId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var poll = jsonDecode(response.body),
          comments = poll['comments'];

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

  Future likeComment(String commentId, bool liked) async {
    String url = API_URL + 'comment/like/' + commentId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'liked': liked});

    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var comment = jsonDecode(response.body)['comment'];

      return comment;
    } else {
      return null;
    }
  }
}

CommentMethods commentMethods = new CommentMethods();

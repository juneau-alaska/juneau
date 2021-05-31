import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/controllers/richTextController.dart';
import 'package:juneau/common/methods/commentMethods.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/numberMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/profile/profile.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentWidget extends StatefulWidget {
  final user;
  final comment;

  CommentWidget({
    Key key,
    @required this.user,
    this.comment,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  var comment;
  var creator;
  var profilePhoto;

  String time;
  bool liked = false;
  int likes = 0;

  // RichTextController inputController = RichTextController({
  //   RegExp(r"\B@[a-zA-Z0-9_.]+\b"): TextStyle(
  //     color: Colors.blueAccent,
  //   ),
  // });
  //
  // RegExp regExp = RegExp(r"\B@[a-zA-Z0-9]+\b");

  @override
  void initState() {
    comment = widget.comment;
    time = numberMethods.convertTime(comment['createdAt']);

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
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: RichText(
                      text: TextSpan(
                        text: '',
                        children: <TextSpan>[
                          if (creator != null)
                            TextSpan(
                              recognizer: TapGestureRecognizer()..onTap = () {
                                openProfile(context, creator, user: widget.user);
                              },
                              text: creator['username'] + ' ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          TextSpan(
                            text: comment['comment'],
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
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
                        onTap: () {

                        },
                        child: Text(
                          likes == 1 ? '1 Like' : '$likes Likes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

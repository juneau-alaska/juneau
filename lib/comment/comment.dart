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
  var creator;
  var profilePhoto;

  String time;

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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    child: profilePhoto != null
                      ? Container(
                      width: 24,
                      height: 24,
                      child: ClipOval(
                        child: Image.memory(
                          profilePhoto,
                          fit: BoxFit.cover,
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                    )
                      : CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage('images/profile.png'),
                    ),
                    onTap: () {
                      openProfile(context, creator);
                    },
                  ),
                ),

                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: '',
                      children: <TextSpan>[
                        TextSpan(
                          recognizer: TapGestureRecognizer()..onTap = () {
                            // openProfile(context, creator, user: user);
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
                        TextSpan(
                          text: ' $time',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ],
        ),
      ),
    );
  }
}

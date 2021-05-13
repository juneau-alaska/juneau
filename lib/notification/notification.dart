import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:juneau/common/colors.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/profile/profile.dart';

import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatefulWidget {
  final notification;

  NotificationItem({
    Key key,
    @required this.notification,
  }) : super(key: key);

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  var notification;
  var user;
  var profilePhoto;
  DateTime createdAt;
  String time;
  String redirectType;

  @override
  void initState() {
    notification = widget.notification;

    createdAt = DateTime.parse(notification['created_at']);
    time = timeago.format(createdAt, locale: 'en_short');

    if (notification['pollId'] != null) {
      redirectType = 'poll';
    } else if (notification['comment'] != null) {
      redirectType = 'comment';
    } else {
      redirectType = 'user';
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      user = await userMethods.getUser(notification['sender']);
      String profilePhotoUrl = user['profilePhoto'];
      if (profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return GestureDetector(
        onTap: () {
          if (redirectType == 'poll') {
            // MAKE openPoll FUNCTION in POLL.DART
          } else if (redirectType == 'comment') {
            // IF TAGGED OR REPLIED TO
          } else if (redirectType == 'user') {
            openProfile(context, user);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // PROFILE PHOTO
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
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
              ),

              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: '',
                    children: <TextSpan>[
                      TextSpan(
                        recognizer: TapGestureRecognizer()..onTap = () {
                          openProfile(context, user);
                        },
                        text: user['username'] + ' ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: notification['read_by'].length == 0
                            ? customColors.white
                            : Theme.of(context).hintColor,
                        ),
                      ),
                      TextSpan(
                        text: notification['message'] + ' ',
                        style: TextStyle(
                          color: notification['read_by'].length == 0
                            ? customColors.white
                            : Theme.of(context).hintColor,
                        ),
                      ),
                      TextSpan(
                        text: '$time',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container();
  }
}

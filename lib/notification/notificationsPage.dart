import 'package:flutter/material.dart';

import 'package:juneau/common/methods/notificationMethods.dart';
import 'package:juneau/notification/notification.dart';

class NotificationsPage extends StatefulWidget {
  final user;
  final notifications;

  NotificationsPage({
    Key key,
    @required this.user,
    this.notifications,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  var user;
  List notifications;
  List<Widget> notificationWidgets;

  List<Widget> buildNotifications() {
    List<Widget> notificationItems = [];

    for (int i=0; i<notifications.length; i++) {
      notificationItems.add(new NotificationItem(user: user, notification: notifications[i]));
    }

    return notificationItems;
  }

  @override
  void initState() {
    user = widget.user;
    notifications = widget.notifications;
    notificationWidgets = buildNotifications();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26.0,
            ),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: ListView(
              children: notificationWidgets,
            ),
          ),
        ),
      ],
    );
  }
}
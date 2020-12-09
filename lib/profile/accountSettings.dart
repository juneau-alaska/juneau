import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettings extends StatefulWidget {
  final user;

  AccountSettings({
    Key key,
    @required this.user,
  }) : super(key: key);

  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {

  void logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs?.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 40.0),
        decoration: new BoxDecoration(
          borderRadius: new BorderRadius.circular(8.0),
          color: Theme.of(context).backgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GestureDetector(
            //   onTap: () {
            //     // TODO: OPEN NOTIFICATIONS MODAL
            //   },
            //   behavior: HitTestBehavior.opaque,
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
            //     child: Container(
            //       child: Row(children: [
            //         Icon(Icons.notifications, size: 25.0),
            //         SizedBox(
            //           width: 13.0,
            //         ),
            //         Text(
            //           'Notfications',
            //           style: TextStyle(fontSize: 15.0)
            //         )
            //       ])),
            //   ),
            // ),
            GestureDetector(
              onTap: () {
                // TODO: OPEN CHANGE PASSWORD MODAL
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
                child: Container(
                  child: Row(children: [
                    Icon(Icons.vpn_key, size: 25.0),
                    SizedBox(
                      width: 13.0,
                    ),
                    Text(
                      'Change Password',
                      style: TextStyle(fontSize: 15.0)
                    )
                  ])),
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     // TODO: OPEN REPORT MODAL
            //   },
            //   behavior: HitTestBehavior.opaque,
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
            //     child: Container(
            //       child: Row(children: [
            //         Icon(Icons.bug_report, size: 25.0),
            //         SizedBox(
            //           width: 13.0,
            //         ),
            //         Text(
            //           'Report a Problem',
            //           style: TextStyle(fontSize: 15.0)
            //         )
            //       ])),
            //   ),
            // ),
            GestureDetector(
              onTap: () {
                logout(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text('Log Out ' + widget.user['username'],
                    style: TextStyle(fontSize: 15.0, color: Theme.of(context).highlightColor)),
              ),
            ),
          ],
        ));
  }
}

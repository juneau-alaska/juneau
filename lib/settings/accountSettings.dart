import 'package:flutter/material.dart';
import 'package:juneau/settings/changePassword.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(5.0),
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
              //     padding: const EdgeInsets.all(15.0),
              //     child: Container(
              //       child: Row(children: [
              //         Icon(Icons.notifications, size: 23.0),
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
                  Navigator.pop(context);
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext context) {
                        return new ChangePasswordModal(
                          user: widget.user,
                        );
                      });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key, size: 23.0),
                        SizedBox(
                          width: 13.0,
                        ),
                        Text('Change Password', style: TextStyle(fontSize: 15.0))
                      ],
                    ),
                  ),
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     // TODO: OPEN REPORT MODAL
              //   },
              //   behavior: HitTestBehavior.opaque,
              //   child: Padding(
              //     padding: const EdgeInsets.all(15.0),
              //     child: Container(
              //       child: Row(children: [
              //         Icon(Icons.bug_report, size: 23.0),
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
                  child: Container(
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 23.0),
                        SizedBox(
                          width: 13.0,
                        ),
                        Text(
                          'Log out ' + widget.user['username'],
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

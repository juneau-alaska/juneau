import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final user;

  ProfilePage({Key key,
    @required this.user,
  })
    : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  void logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs?.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlatButton(
          onPressed: () {
            logout(context);
          },
          child: Text('LOGOUT'),
        )
      ],
    );
  }
}

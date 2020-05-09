import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/appBar.dart';
import 'package:juneau/home/poll.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void logoutUser(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs?.clear();
  Navigator.of(context)
      .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
}

Future<List> _getPolls() async {
  const url = 'http://localhost:4000/polls';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(
      url,
      headers: headers
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }
}

List createPages(polls) {
  List<Widget> pages = [];
  for (var i = 0; i < polls.length; i++) {
    var poll = polls[i];
    pages.add(new PollWidget(poll: poll));
  }
  return pages;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  var polls;

  @override
  void initState() {
    _getPolls().then((result){
      setState(() {
        if (result != null) {
          polls = result;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (polls == null) {
      return new Container();
    }

    List pages = createPages(polls);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: appBar,
      body: PageView(
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.mail_outline),
            activeIcon: new Icon(Icons.mail),
            title: new Text(''),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.mail_outline),
            activeIcon: new Icon(Icons.mail),
            title: new Text(''),
          ),
        ]
      ),
    );
  }
}

//class CollectPersonalInfoPage extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return DefaultTextStyle(
//      style: Theme.of(context).textTheme.display1,
//      child: GestureDetector(
//        onTap: () {
//          // This moves from the personal info page to the credentials page,
//          // replacing this page with that one.
//          Navigator.of(context)
//              .pushReplacementNamed('signup/choose_credentials');
//        },
//        child: Container(
//          color: Colors.lightBlue,
//          alignment: Alignment.center,
//          child: Text('Collect Personal Info Page'),
//        ),
//      ),
//    );
//  }
//}

//class ChooseCredentialsPage extends StatelessWidget {
//  const ChooseCredentialsPage({
//    this.onSignupComplete,
//  });
//
//  final VoidCallback onSignupComplete;
//
//  @override
//  Widget build(BuildContext context) {
//    return GestureDetector(
//      onTap: onSignupComplete,
//      child: DefaultTextStyle(
//        style: Theme.of(context).textTheme.display1,
//        child: Container(
//          color: Colors.pinkAccent,
//          alignment: Alignment.center,
//          child: Text('Choose Credentials Page'),
//        ),
//      ),
//    );
//  }
//}
//
//class SignUpPage extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    // SignUpPage builds its own Navigator which ends up being a nested
//    // Navigator in our app.
//    return Navigator(
//      initialRoute: 'signup/personal_info',
//      onGenerateRoute: (RouteSettings settings) {
//        WidgetBuilder builder;
//        switch (settings.name) {
//          case 'signup/personal_info':
//          // Assume CollectPersonalInfoPage collects personal info and then
//          // navigates to 'signup/choose_credentials'.
//            builder = (BuildContext _) => CollectPersonalInfoPage();
//            break;
//          case 'signup/choose_credentials':
//          // Assume ChooseCredentialsPage collects new credentials and then
//          // invokes 'onSignupComplete()'.
//            builder = (BuildContext _) => ChooseCredentialsPage(
//              onSignupComplete: () {
//                // Referencing Navigator.of(context) from here refers to the
//                // top level Navigator because SignUpPage is above the
//                // nested Navigator that it created. Therefore, this pop()
//                // will pop the entire "sign up" journey and return to the
//                // "/" route, AKA HomePage.
//                Navigator.of(context).pop();
//              },
//            );
//            break;
//          default:
//            throw Exception('Invalid route: ${settings.name}');
//        }
//        return MaterialPageRoute(builder: builder, settings: settings);
//      },
//    );
//  }
//}
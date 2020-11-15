import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/auth/loginSelect.dart';
import 'package:juneau/auth/login.dart';
import 'package:juneau/auth/signUpSelect.dart';
import 'package:juneau/auth/signUp.dart';
import 'package:juneau/home/home.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    Color black = const Color(0xFF020202);

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        backgroundColor: const Color(0xFFFEFEFE),
        hintColor: const Color(0xFF9c9e9f),
        highlightColor: const Color(0xFFf75463),
        accentColor: const Color(0xFFf75463), // const Color(0xFF02419E),  // GREEN 125641 BLUE 02419E
        buttonColor: black,
        textTheme: TextTheme(
          headline1: TextStyle(color: black),
          headline6: TextStyle(color: black),
          bodyText2: TextStyle(color: black),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (BuildContext context) => SplashScreen(),
        '/home': (BuildContext context) => HomePage(),
        '/loginSelect': (BuildContext context) => LoginSelectPage(),
        '/login': (BuildContext context) => LoginPage(),
        '/signUpSelect': (BuildContext context) => SignUpSelectPage(),
        '/signUp': (BuildContext context) => SignUpPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Container(
          width: 300.0,
          height: 300.0,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/cubesmelt.gif"), fit: BoxFit.fitWidth),
          ),
        ),
      ),
    );
  }

  void startTimer() {
    Timer(Duration(seconds: 3), () {
      navigateUser();
    });
  }

  void navigateUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('isLoggedIn') ?? false;
    if (status) {
      Navigator.pushNamed(context, '/home');
    } else {
      Navigator.pushNamed(context, '/signUpSelect');
    }
  }
}

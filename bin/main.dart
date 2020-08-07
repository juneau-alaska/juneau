import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/auth/login.dart';
import 'package:juneau/auth/signup.dart';
import 'package:juneau/home/home.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    Color white = const Color(0xFFD7DADC);

    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF181818),
        cardColor: const Color(0xFF313131),
        highlightColor: const Color(0xFF494949),
        accentColor: const Color(0xFFbfff00),

        textTheme: TextTheme(
          bodyText1: TextStyle(fontFamily: 'Lato Regular'),
          bodyText2: TextStyle(fontFamily: 'Lato Regular'),
        ).apply(
          bodyColor: white,
          displayColor: white,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (BuildContext context) => SplashScreen(),
        '/home': (BuildContext context) => HomePage(),
        '/login': (BuildContext context) => LoginPage(),
        '/signup': (BuildContext context) => SignUpPage(),
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
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Container(
          width: 300.0,
          height: 300.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/cubesmelt.gif"),
              fit: BoxFit.contain
            ),
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

  void navigateUser() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('isLoggedIn') ?? false;
    if (status) {
      Navigator.pushNamed(context, '/home');
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }
}
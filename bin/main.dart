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

    Color white = const Color(0xffDFDEDE);
    Color blue = const Color(0xff35476F);
    Color lightBlue = const Color(0xff7898C2);
    Color greyBlue = new Color(0xff415581);
    Color lightGrey = new Color(0xffDEDDDD);

    Color primary;
    Color secondary;
    Color accent = lightBlue;
    Color input;
    Brightness brightness;

    var dark = false;

    if (dark) {
      primary = blue;
      secondary = white;
      input = greyBlue;
      brightness = Brightness.dark;
    } else {
      primary = white;
      secondary = blue;
      input = lightGrey;
      brightness = Brightness.light;
    }

    final newTextTheme = Theme.of(context).textTheme.apply(
      fontFamily: 'Lato Regular',
      bodyColor: secondary,
      displayColor: secondary,
    );

    return MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        primaryColor: primary,
        cardColor: primary,
        buttonColor: secondary,
        accentColor: accent,
        dialogBackgroundColor: input,
        textTheme: newTextTheme,
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
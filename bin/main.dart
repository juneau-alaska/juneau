import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juneau/auth/login.dart';
import 'package:juneau/auth/loginSelect.dart';
import 'package:juneau/auth/signUp.dart';
import 'package:juneau/auth/signUpSelect.dart';
import 'package:juneau/common/colors.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/notificationMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/views/appBar.dart';
import 'package:juneau/common/views/navBar.dart';
import 'package:juneau/home/home.dart';
import 'package:juneau/search/search.dart';
import 'package:juneau/profile/profile.dart';
import 'package:juneau/notification/notificationsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        backgroundColor: customColors.white,
        primaryColor: customColors.black,
        hintColor: customColors.darkGrey,
        dividerColor: customColors.lightGrey,
        highlightColor: Colors.blue,
        indicatorColor: Colors.red,
        buttonColor: customColors.black,
        textTheme: TextTheme(
          headline1: TextStyle(
            color: customColors.black,
            letterSpacing: -0.25,
          ),
          headline6: TextStyle(
            color: customColors.black,
            letterSpacing: -0.25,
          ),
          bodyText2: TextStyle(
            color: customColors.black,
            letterSpacing: -0.25,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: customColors.black,
        primaryColor: customColors.white,
        hintColor: customColors.lightGrey,
        dividerColor: customColors.darkGrey,
        highlightColor: Colors.blueAccent,
        indicatorColor: Colors.redAccent,
        buttonColor: customColors.white,
        textTheme: TextTheme(
          headline1: TextStyle(
            color: customColors.white,
            letterSpacing: -0.25,
          ),
          headline6: TextStyle(
            color: customColors.white,
            letterSpacing: -0.25,
          ),
          bodyText2: TextStyle(
            color: customColors.white,
            letterSpacing: -0.25,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (BuildContext context) => SplashScreen(),
        '/main': (BuildContext context) => MainScaffold(),
        '/loginSelect': (BuildContext context) => LoginSelectPage(),
        '/login': (BuildContext context) => LoginPage(),
        '/signUpSelect': (BuildContext context) => SignUpSelectPage(),
        '/signUp': (BuildContext context) => SignUpPage(),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  var user;
  Widget appBar;
  Widget navBar;
  Widget homePage;
  Widget searchPage;
  Widget profilePage;
  Widget notificationsPage;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PageController _pageController = PageController();
  final StreamController _navController = StreamController();
  final StreamController _profileController = StreamController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId');
      user = await userMethods.getUser(userId);

      String profilePhotoUrl = user['profilePhoto'];
      var profilePhoto;
      if (profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }

      List notifications = await notificationMethods.getNotifications(userId);
      List unreadIds = [];

      for (var i=0; i<notifications.length; i++) {
        var notification = notifications[i];
        if (notification['read_by'].length == 0) {
          unreadIds.add(notification['_id']);
        }
      }

      homePage = HomePage(userId: userId);
      searchPage = SearchPage(userId: userId);
      notificationsPage = NotificationsPage(user: user, notifications: notifications, unreadIds: unreadIds);
      profilePage = ProfilePage(
          profileUser: user, profilePhoto: profilePhoto, profileController: _profileController);
      navBar = NavBar(
          navigatorKey: _navigatorKey,
          navController: _navController,
          profilePhoto: profilePhoto,
          profileController: _profileController,
          unreadLength: unreadIds.length,
      );
      appBar = ApplicationBar(height: 0.0);

      _navController.stream.listen((index) async {
        _pageController.jumpToPage(index);
      });

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navController.close();
    _profileController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress)
          return false;
        else
          return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: appBar,
        body: user != null
            ? PageView(
                physics: new NeverScrollableScrollPhysics(),
                children: [
                  homePage,
                  searchPage,
                  notificationsPage,
                  profilePage,
                ],
                controller: _pageController,
              )
            : Container(),
        bottomNavigationBar: navBar,
      ),
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
        // child: Image(
        //   image: MediaQuery.of(context).platformBrightness == Brightness.dark
        //     ? AssetImage('images/icon_white.png')
        //     : AssetImage('images/icon_black.png')
        // ),
        child: Text(
          'ARTFOLK',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
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
      Navigator.pushNamed(context, '/main');
    } else {
      Navigator.pushNamed(context, '/signUpSelect');
    }
  }
}

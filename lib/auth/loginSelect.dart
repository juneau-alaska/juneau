import 'package:flutter/material.dart';

class LoginSelectPage extends StatefulWidget {
  @override
  _LoginSelectPageState createState() => _LoginSelectPageState();
}

class _LoginSelectPageState extends State<LoginSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Text('Login',
                  style: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold)))),
            Column(children: [
              FlatButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.email),
                      Center(
                        child: Text('Log in with email'),
                      ),
                      Container()
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).hintColor, width: 1, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(50)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 50.0, 30.0, 10.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signUpSelect');
                    },
                    child: Text('Sign up', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ]),
              )
            ])
          ]),
      ));
  }
}

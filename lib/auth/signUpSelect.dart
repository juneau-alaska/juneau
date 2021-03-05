import 'package:flutter/material.dart';

class SignUpSelectPage extends StatefulWidget {
  @override
  _SignUpSelectPageState createState() => _SignUpSelectPageState();
}

class _SignUpSelectPageState extends State<SignUpSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 30.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50.0),
                    child: Text('Sign up',
                        style: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold)))),
            Column(children: [
              FlatButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signUp');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.email),
                      Center(
                        child: Text('Sign up with email'),
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
                      Navigator.pushNamed(context, '/loginSelect');
                    },
                    child: Text('Log in', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ]),
              )
            ])
          ]),
        ));
  }
}

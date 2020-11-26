import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/poll/pollPreview.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

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
  bool firstLoad = false;
  String prevId;
  List polls;
  List<Widget> pollsList;
  Widget gridView;
  BuildContext profileContext;

  void logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs?.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
  }

  Future<List> getPolls() async {
    const url = 'http://localhost:4000/polls';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'prevId': prevId, 'createdBy': widget.user['_id']});

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse.length > 0) {
        prevId = jsonResponse.last['_id'];
      }

      return jsonResponse;
    } else {
      showAlert(context, 'Something went wrong, please try again');
      return null;
    }
  }

  @override
  void initState() {
    prevId = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      polls = await getPolls();
      setState(() {});
    });

    super.initState();
  }

  Widget createPolls() {
    pollsList = [];
    for (var i = 0; i < polls.length; i++) {
      var poll = polls[i];
      pollsList.add(
        Container(
          key: UniqueKey(),
          child: PollPreview(poll: poll),
        ),
      );
    }
    return Flexible(
      child: ListView(
        children: pollsList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (polls == null) {
      return Container();
    }

    if (!firstLoad) {
      firstLoad = true;
      profileContext = context;
      gridView = createPolls();
    }

    return Column(
      children: [
        FlatButton(
          onPressed: () {
            logout(context);
          },
          child: Text('LOGOUT'),
        ),
        Text(
          widget.user['username'],
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold
          ),
        ),
        gridView != null
          ? gridView : Container(),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 0.0),
        //   child: GridView.count(
        //     crossAxisCount: 3,
        //     children: List.generate(images.length, (index) {
        //       Asset asset = images[index];
        //       return Padding(
        //         padding: const EdgeInsets.all(0.0),
        //         child: AssetThumb(
        //           asset: asset,
        //           width: images.length > 4 ? 300 : 600,
        //           height: images.length > 4 ? 300 : 600,
        //         ),
        //       );
        //     }),
        //   ),
        // ),
      ],
    );
  }
}

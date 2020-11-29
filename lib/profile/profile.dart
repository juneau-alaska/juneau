import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:juneau/common/components/keepAlivePage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/poll/pollPreview.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  final user;

  ProfilePage({
    Key key,
    @required this.user,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String prevId;
  Widget gridListView;
  BuildContext profileContext;
  List pollObjects;

  bool preventReload = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  void logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs?.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
  }

  Future<List<int>> getImageBytes(option) async {
    String url = option['content'];
    List<int> imageBytes;

    var response = await http.get(url);
    if (response.statusCode == 200) {
      imageBytes = response.bodyBytes;
    }

    return imageBytes;
  }

  Future<List> getOptions(poll) async {
    const url = 'http://localhost:4000/option';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    List optionIds = poll['options'];
    List<Future> futures = [];
    List options;

    for (var i = 0; i < optionIds.length; i++) {
      var optionId = optionIds[i];
      Future future() async {
        var response = await http.get(
          url + '/' + optionId,
          headers: headers,
        );

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          return jsonResponse;
        } else {
          print('Request failed with status: ${response.statusCode}.');
          return null;
        }
      }

      futures.add(future());
    }

    await Future.wait(futures).then((results) {
      options = results;
    });

    return options;
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

  Future fetchPollData(bool next) async {
    if (!next) {
      pollObjects = [];
    }
    List polls = await getPolls();
    for (var i = 0; i < polls.length; i++) {
      var poll = polls[i];
      List options = await getOptions(poll);
      List images = [];

      for (var j = 0; j < options.length; j++) {
        var option = options[j];
        List<int> image = await getImageBytes(option);
        images.add(image);
      }

      pollObjects.add({
        'poll': poll,
        'options': options,
        'images': images,
        'index': i,
      });
    }
    setState(() {});
  }

  @override
  void initState() {
    prevId = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchPollData(false);
    });

    super.initState();
  }

  Widget createGridList() {
    List<Widget> pollsList = [];
    List<Widget> gridRow = [];

    for (var i = 0; i < pollObjects.length; i++) {
      var pollObject = pollObjects[i];

      gridRow.add(Padding(
        padding: const EdgeInsets.all(0.5),
        child: PollPreview(pollObject: pollObject),
      ));

      if ((i+1) % 3 == 0) {
        pollsList.add(
          Padding(
            padding: const EdgeInsets.all(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gridRow
            ),
          ),
        );
        gridRow = [];
      }
    }

    return ListView(
      children: pollsList,
    );
  }

  void _onRefresh() async {
    preventReload = false;
    prevId = null;
    await fetchPollData(false);
    refreshController.refreshCompleted();
  }

  void _onLoading() async {
    preventReload = false;
    await fetchPollData(true);
    refreshController.loadComplete();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (pollObjects != null && !preventReload) {
      preventReload = true;
      profileContext = context;
      gridListView = createGridList();
    }

    return Column(
      children: [
        // FlatButton(
        //   onPressed: () {
        //     logout(context);
        //   },
        //   color: Colors.deepPurple,
        //   child: Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
        // ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          child: Text(
            widget.user['username'],
            style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Follow',
                ),
              ),
              SizedBox(width: 5.0),
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Message',
                ),
              )
            ],
          ),
        ),
        pollObjects != null
            ? pollObjects.length > 0
                ? Flexible(
                    child: KeepAlivePage(
                      child: SmartRefresher(
                        enablePullDown: true,
                        enablePullUp: true,
                        header: ClassicHeader(),
                        footer: ClassicFooter(
                          loadStyle: LoadStyle.ShowWhenLoading,
                        ),
                        controller: refreshController,
                        onRefresh: _onRefresh,
                        onLoading: _onLoading,
                        child: gridListView,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Center(
                      child: Container(child: Text('No created polls found')),
                    ),
                  )
            : Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Center(
                  child: Container(child: CircularProgressIndicator()),
                ),
              ),
      ],
    );
  }
}

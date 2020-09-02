import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:path/path.dart' as p;

import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/components/alertComponent.dart';

Future generatePreAssignedUrl(String fileType) async {
  const url = 'http://localhost:4000/option/generatePreAssignedUrl';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body, response;

  body = jsonEncode({'fileType': fileType});

  response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  } else {
    throw ('Request failed with status: ${response.statusCode}.');
  }
}

Future<void> uploadFile(String url, Asset asset) async {
  try {
    ByteData byteData = await asset.getThumbByteData(600, 600);
    var response = await http.put(url, body: byteData.buffer.asUint8List());
    if (response.statusCode == 200) {
      print('Successfully uploaded photo');
    }
  } catch (e) {
    throw ('Error uploading photo');
  }
}

void createOptions(prompt, options, context) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body, response;

  List<Future> futures = [];

  for (var i = 0; i < options.length; i++) {
    Future future() async {
      body = jsonEncode({'content': options[i]});

      response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['_id'];
      } else {
        throw ('Request failed with status: ${response.statusCode}.');
      }
    }

    futures.add(future());
  }

  await Future.wait(futures).then((results) {
    createPoll(prompt, results, context);
  }).catchError((err) {
    return showAlert(context, 'Something went wrong, please try again');
  });
}

void createPoll(prompt, optionIds, context) async {
  const url = 'http://localhost:4000/poll';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body =
      jsonEncode({'prompt': prompt, 'options': optionIds, 'createdBy': userId});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), pollId = jsonResponse['_id'];

    updateUserCreatedPolls(pollId, context);
  } else {
    return showAlert(context, 'Something went wrong, please try again');
  }
}

void updateUserCreatedPolls(pollId, context) async {
  const url = 'http://localhost:4000/user/';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url + userId, headers: headers);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body)[0],
        createdPolls = jsonResponse['createdPolls'];

    createdPolls.add(pollId);

    var body = jsonEncode({'createdPolls': createdPolls});

    response = await http.put(url + userId, headers: headers, body: body);
    Navigator.pop(context);
  } else {
    return showAlert(context, 'Something went wrong, please try again');
  }
}

class PollCreate extends StatefulWidget {
  @override
  _PollCreateState createState() => _PollCreateState();
}

class _PollCreateState extends State<PollCreate> {
  InputComponent questionInput = new InputComponent(
    hintText: 'Provide an interesting title',
    obscureText: false,
    maxLines: 4,
    borderColor: Colors.transparent,
    padding: 0.0,
    fontSize: 16.0,
  );

  List<Asset> images = List<Asset>();

  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: images.length > 4 ? 3 : 2,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: AssetThumb(
            asset: asset,
            width: images.length > 4 ? 300 : 600,
            height: images.length > 4 ? 300 : 600,
          ),
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();

    resultList = await MultiImagePicker.pickImages(
      maxImages: 9,
      enableCamera: true,
      selectedAssets: images,
      cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
      materialOptions: MaterialOptions(
        actionBarColor: "#58E0C0",
        actionBarTitle: "Juneau",
        allViewTitle: "All Photos",
        useDetailsView: false,
        selectCircleStrokeColor: "#58E0C0",
      ),
    );

    if (!mounted) return;

    setState(() {
      images = resultList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 65.0, 15.0, 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  "Create New Poll",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    String prompt = questionInput.controller.text;
                    List options = [];

                    if (prompt == null ||
                        prompt.replaceAll(new RegExp(r"\s+"), "").length == 0) {
                      return showAlert(context, 'Please provide a title');
                    }

                    if (images.length >= 2) {
                      for (int i = 0; i < images.length; i++) {
                        String path = await FlutterAbsolutePath.getAbsolutePath(
                            images[i].identifier);

                        final file = File(path);
                        if (!file.existsSync()) {
                          file.createSync(recursive: true);
                        }

                        String fileExtension = p.extension(file.path);
                        var preAssignedUrl =
                            await generatePreAssignedUrl(fileExtension)
                                .catchError((err) {
                          return showAlert(context,
                              'Something went wrong, please try again');
                        });

                        String uploadUrl = preAssignedUrl['uploadUrl'];
                        String downloadUrl = preAssignedUrl['downloadUrl'];

                        await uploadFile(uploadUrl, images[i]).then((result) {
                          options.add(downloadUrl);
                        }).catchError((err) {
                          return showAlert(context,
                              'Something went wrong, please try again');
                        });
                      }
                      // TODO: LOADING BAR OR SPINNER WHILE THIS TAKES PLACE? MAKE A COMPONENT?
                    } else {
                      return showAlert(context, 'Please select at least 2 images');
                    }

                    if (options.length >= 2) {
                      createOptions(prompt, options, context);
                    } else {
                      return showAlert(
                          context, 'Something went wrong, please try again');
                    }
                  },
                  child: Text(
                    "Create",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          questionInput,
          SizedBox(height: 30.0),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      "Add Options",
                      style: TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w600),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 3.0, top: 1.0),
                      child: Text(
                        "(max 9)",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(right: 15.0),
                  child: GestureDetector(
                    onTap: loadAssets,
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 18.0,
                        ),
                        SizedBox(width: 5.0),
                        Text(
                          "SELECT IMAGES",
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.0),
          Expanded(
            child: buildGridView(),
          ),
        ],
      ),
    );
  }
}
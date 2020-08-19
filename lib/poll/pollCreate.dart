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

Future generatePreAssignedUrl(String fileType) async {
  const url = 'http://localhost:4000/option/generatePreAssignedUrl';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body, response;

  body = jsonEncode({
    'fileType': fileType
  });

  response = await http.post(
    url,
    headers: headers,
    body: body
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }
}

Future<void> uploadFile(String url, Asset asset) async {
  try {
    ByteData byteData = await asset.getByteData();

    var response = await http.put(url, body: byteData.buffer.asUint8List());
    if (response.statusCode == 200) {
      print('Successfully uploaded photo');
    }
  } catch (e) {
    print(e);
    throw ('Error uploading photo');
  }
}

void createOptions(prompt, options, type) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body, response;

  List<Future> futures = [];

  for (var i = 0; i < options.length; i++) {
    Future future() async {
      body = jsonEncode({
        'content': options[i],
        'type': type
      });

      response = await http.post(
          url,
          headers: headers,
          body: body
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['_id'];
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    }
    futures.add(future());
  }

  // TODO: PREVENT CREATING POLL IF OPTIONS FAIL AND DON'T CLOSE MODAL
  await Future.wait(futures)
    .then((results) {
      createPoll(prompt, results);
    });
}

void createPoll(prompt, optionIds) async {
  const url = 'http://localhost:4000/poll';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'),
      userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode({
    'prompt': prompt,
    'options': optionIds,
    'createdBy': userId
  });

  var response = await http.post(
      url,
      headers: headers,
      body: body
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body),
        pollId = jsonResponse['_id'];

    updateUserCreatedPolls(pollId);
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

void updateUserCreatedPolls(pollId) async {
  const url = 'http://localhost:4000/user/';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'),
      userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader : 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(
      url + userId,
      headers: headers
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body)[0],
        createdPolls = jsonResponse['createdPolls'];

    createdPolls.add(pollId);

    var body = jsonEncode({
      'createdPolls': createdPolls
    });

    response = await http.put(
      url + userId,
      headers: headers,
      body: body
    );

    if (response.statusCode != 200) {
      print('Request failed with status: ${response.statusCode}.');
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

class PollCreate extends StatefulWidget {
  @override
  _PollCreateState createState() => _PollCreateState();
}

class _PollCreateState extends State<PollCreate> {
  bool isText = true;

  InputComponent questionInput = new InputComponent(
    hintText: 'Ask a question...',
    obscureText: false,
    maxLines: 4,
    borderColor: Colors.transparent,
    padding: 0.0,
    fontSize: 15.0,
  );

  List<InputComponent> inputComponents = [
    new InputComponent(hintText: 'Option #1', obscureText: false),
    new InputComponent(hintText: 'Option #2', obscureText: false),
  ];

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

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
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
        children: <Widget> [
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
                    String prompt  = questionInput.controller.text;
                    String type = isText ? 'text' : 'image';
                    List options = [];

                    if (isText && inputComponents.length >= 2) {
                      for (int i=0; i<inputComponents.length; i++) {
                        InputComponent inputComponent = inputComponents[i];
                        String text = inputComponent.controller.text;
                        if (text != "" && text != " ") {
                          options.add(inputComponent.controller.text);
                        }
                      }
                    } else if (images.length >= 2) {
                      for (int i = 0; i < images.length; i++) {
                        // TODO: GENERATE S3 URL FROM BACKEND AND ADD THE URL TO OPTIONS
                        String path = await FlutterAbsolutePath.getAbsolutePath(images[i].identifier);

                        final file = File(path);
                        if (!file.existsSync()) {
                          file.createSync(recursive: true);
                        }

                        String fileExtension = p.extension(file.path);
                        var preAssignedUrl = await generatePreAssignedUrl(fileExtension);

                        if (preAssignedUrl != null) {
                          String uploadUrl = preAssignedUrl['uploadUrl'];
                          String downloadUrl = preAssignedUrl['downloadUrl'];

                          await uploadFile(uploadUrl, images[i]);
                          options.add(downloadUrl);

                        } else {
                          // TODO: LOAD ERROR MESSAGE POPUP
                        }
                      }
                      // TODO: LOADING BAR OR SPINNER WHILE THIS TAKES PLACE? MAKE A COMPONENT?
                    }

                    // TODO: WAIT FOR IMAGE TO GENERATE URL FROM S3
                    if (options.length >= 2) {
                      createOptions(prompt, options, type);
                      Navigator.pop(context);
                    } else {
                      // TODO: DISPLAY ERROR POPUP OR TEXT
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
          Container(
            margin: const EdgeInsets.only(top: 5.0, bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isText = true;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width/2 - 15,
                    alignment: Alignment.center,
                    decoration: new BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: isText ? 2.0 : 1.0,
                          color: isText ? Colors.white : Theme.of(context).hintColor
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                      child: Text(
                        "Text",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: isText ? Colors.white : Theme.of(context).hintColor
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isText = false;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width/2 - 15,
                    alignment: Alignment.center,
                    decoration: new BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: isText ? 1.0 : 2.0,
                          color: isText ? Theme.of(context).hintColor : Colors.white
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                      child: Text(
                        "Image",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: isText ? Theme.of(context).hintColor : Colors.white
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          questionInput,
          SizedBox(
            height: 30.0
          ),
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
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600
                      ),
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
                isText ? Container() : Container(
                  margin: const EdgeInsets.only(right: 15.0),
                  child: GestureDetector(
                    onTap: loadAssets,
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 18.0,
                        ),
                        SizedBox(
                          width: 5.0
                        ),
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
          SizedBox(
            height: 10.0
          ),
          isText ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: inputComponents,
          ) : Container(

          ),
          isText ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.5),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      width: 0.5,
                      color: Theme.of(context).hintColor
                  )
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    var inputCount = inputComponents.length;
                    var optionNum = inputCount + 1;

                    if (inputCount < 9) {
                      inputComponents.add(
                        new InputComponent(
                          hintText: 'Option #$optionNum',
                          obscureText: false,
                        )
                      );
                    }
                  });
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11.0, 12.0, 11.0, 12.0),
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 25.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ) : Expanded(
            child: buildGridView(),
          ),
        ],
      ),
    );
  }
}

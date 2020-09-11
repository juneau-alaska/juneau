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

import 'package:juneau/category/categorySearchSelect.dart';

Future generatePreAssignedUrl(String fileType) async {
  const url = 'http://localhost:4000/option/generatePreAssignedUrl';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

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

void createOptions(prompt, options, categories, context) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

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
    createPoll(prompt, results, categories, context);
  }).catchError((err) {
    return showAlert(context, 'Something went wrong, please try again');
  });
}

void createPoll(prompt, optionIds, categories, context) async {
  const url = 'http://localhost:4000/poll';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  var body = jsonEncode({'prompt': prompt, 'options': optionIds, 'categories': categories, 'createdBy': userId});

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

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  var response = await http.get(url + userId, headers: headers);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body)[0], createdPolls = jsonResponse['createdPolls'];

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
    hintText: 'Provide a question...',
    borderColor: Colors.transparent,
    padding: EdgeInsets.symmetric(horizontal: 15.0),
    contentPadding: EdgeInsets.symmetric(vertical: 10.0),
    fontSize: 16.0,
    autoFocus: true,
  );

  List<Asset> images = List<Asset>();

  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.75),
      child: GridView.count(
        crossAxisCount: images.length > 4 ? 3 : 2,
        children: List.generate(images.length, (index) {
          Asset asset = images[index];
          return Padding(
            padding: const EdgeInsets.all(0.75),
            child: AssetThumb(
              asset: asset,
              width: images.length > 4 ? 300 : 600,
              height: images.length > 4 ? 300 : 600,
            ),
          );
        }),
      ),
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
      isLoading = false;
      images = resultList;
    });
  }

  bool isLoading = false;
  List<String> selectedCategories = [""];
  double categoryContainerHeight = 0.0;
  EdgeInsets categoryContainerPadding = EdgeInsets.only(bottom: 10.0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 20.0),
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
                      "Image Poll",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        setState(() {});
                        String prompt = questionInput.controller.text;
                        List options = [];

                        if (prompt == null || prompt.replaceAll(new RegExp(r"\s+"), "").length == 0) {
                          return showAlert(context, 'Please provide a title');
                        }

                        if (images.length >= 2) {
                          isLoading = true;
                          for (int i = 0; i < images.length; i++) {
                            String path = await FlutterAbsolutePath.getAbsolutePath(images[i].identifier);

                            final file = File(path);
                            if (!file.existsSync()) {
                              file.createSync(recursive: true);
                            }

                            String fileExtension = p.extension(file.path);
                            var preAssignedUrl = await generatePreAssignedUrl(fileExtension).catchError((err) {
                              return showAlert(context, 'Something went wrong, please try again');
                            });

                            String uploadUrl = preAssignedUrl['uploadUrl'];
                            String downloadUrl = preAssignedUrl['downloadUrl'];

                            await uploadFile(uploadUrl, images[i]).then((result) {
                              options.add(downloadUrl);
                            }).catchError((err) {
                              isLoading = false;
                              return showAlert(context, 'Something went wrong, please try again');
                            });
                          }
                        } else {
                          isLoading = false;
                          return showAlert(context, 'Please select at least 2 images');
                        }

                        if (options.length >= 2) {
                          createOptions(prompt, options, selectedCategories, context);
                        } else {
                          isLoading = false;
                          return showAlert(context, 'Something went wrong, please try again');
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
              Divider(
                thickness: 1.0,
              ),
              GestureDetector(
                onTap: () async {
                  String selectedCategory = await showModalBottomSheet(
                      isScrollControlled: true, context: context, builder: (BuildContext context) => CategorySearchSelect());

                  if (selectedCategory != null) {
                    if (selectedCategories[0] == "") {
                      selectedCategories[0] = selectedCategory;
                      categoryContainerHeight = 32.0;
                      categoryContainerPadding = const EdgeInsets.fromLTRB(10.0, 9.0, 10.0, 10.0);
                    } else if (!selectedCategories.contains(selectedCategory)) {
                      selectedCategories.add(selectedCategory);
                    }
                    setState(() {});
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Categories",
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 15.0,
                          )
                        ],
                      ),
                    )),
              ),
              Padding(
                padding: categoryContainerPadding,
                child: SizedBox(
                  height: categoryContainerHeight,
                  child: new ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedCategories.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(
                          decoration: new BoxDecoration(
                              color: Theme.of(context).highlightColor, borderRadius: new BorderRadius.all(const Radius.circular(15.0))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Center(
                              child: Row(
                                children: [
                                  Text(
                                    selectedCategories[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 4.0),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategories.removeAt(index);
                                        if (selectedCategories.length == 0) {
                                          selectedCategories.add("");
                                          categoryContainerHeight = 0.0;
                                          categoryContainerPadding = EdgeInsets.only(bottom: 10.0);
                                        }
                                      });
                                    },
                                    child: selectedCategories[index] == ""
                                        ? Container()
                                        : Container(
                                            height: 10.0,
                                            child: Icon(
                                              Icons.clear,
                                              size: 12.0,
                                            ),
                                          ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Divider(
                thickness: 1.0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Add Selections",
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
                    ),
                    Container(
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
                              style: TextStyle(fontSize: 13.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: buildGridView(),
              ),
            ],
          ),
        ),
        isLoading
            ? Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Container()
      ],
    );
  }
}

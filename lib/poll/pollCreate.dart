import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/category/categorySearchSelect.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> createOptions(prompt, options, category, context) async {
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

  bool success;

  await Future.wait(futures).then((results) async {
    success = await createPoll(prompt, results, category, context);
  }).catchError((err) {
    showAlert(context, 'Something went wrong, please try again');
    success = false;
  });

  return success;
}

Future<bool> createPoll(prompt, optionIds, category, context) async {
  const url = 'http://localhost:4000/poll';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var body = jsonEncode(
      {'prompt': prompt, 'options': optionIds, 'category': category, 'createdBy': userId});

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), pollId = jsonResponse['_id'];

    return await updateUserCreatedPolls(pollId, context);
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return false;
  }
}

Future<bool> updateUserCreatedPolls(pollId, context) async {
  const url = 'http://localhost:4000/user/';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token'), userId = prefs.getString('userId');

  var headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: token
  };

  var response = await http.get(url + userId, headers: headers), body;

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body), createdPolls = jsonResponse['createdPolls'];

    createdPolls.add(pollId);
    body = jsonEncode({'createdPolls': createdPolls});

    response = await http.put(url + userId, headers: headers, body: body);

    if (response.statusCode == 200) {
      jsonResponse = jsonDecode(response.body);
      Navigator.pop(context);
      return true;
    } else {
      return false;
    }
  } else {
    showAlert(context, 'Something went wrong, please try again');
    return false;
  }
}

class PollCreate extends StatefulWidget {
  @override
  _PollCreateState createState() => _PollCreateState();
}

class _PollCreateState extends State<PollCreate> {
  InputComponent questionInput = new InputComponent(
    hintText: 'Create a title (Optional)',
    borderColor: Colors.transparent,
    contentPadding: EdgeInsets.symmetric(vertical: 10.0),
    autoFocus: true,
  );

  List<Asset> images = [];
  bool isLoading = false;
  String selectedCategory;
  double categoryContainerHeight = 0.0;
  EdgeInsets categoryContainerPadding = EdgeInsets.only(bottom: 10.0);

  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: GridView.count(
        crossAxisCount: images.length > 4 ? 3 : 2,
        children: List.generate(images.length, (index) {
          Asset asset = images[index];
          return Padding(
            padding: const EdgeInsets.all(0.0),
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

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 9,
        selectedAssets: images,
      );
    } on Exception catch (e) {
      print(e.toString());
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
      images = resultList;
    });
  }

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      "New Poll",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        String prompt = questionInput.controller.text;
                        List options = [];
                        setState(() {});

                        if (images.length >= 2) {
                          isLoading = true;
                          for (int i = 0; i < images.length; i++) {
                            String path =
                                await FlutterAbsolutePath.getAbsolutePath(images[i].identifier);

                            final file = File(path);
                            if (!file.existsSync()) {
                              file.createSync(recursive: true);
                            }

                            String fileExtension = p.extension(file.path);
                            var imageUrl =
                                await imageMethods.getImageUrl(fileExtension, 'poll-option').catchError((err) {
                              showAlert(context, 'Something went wrong, please try again');
                            });

                            if (imageUrl != null) {
                              String uploadUrl = imageUrl['uploadUrl'];
                              String downloadUrl = imageUrl['downloadUrl'];

                              await imageMethods.uploadFile(uploadUrl, images[i]).then((result) {
                                options.add(downloadUrl);
                              }).catchError((err) {
                                isLoading = false;
                                showAlert(context, 'Something went wrong, please try again');
                              });
                            }
                          }
                        } else {
                          isLoading = false;
                          showAlert(context, 'Please select at least 2 images');
                        }

                        if (options.length >= 2) {
                          isLoading =
                              await createOptions(prompt, options, selectedCategory, context);
                        } else {
                          isLoading = false;
                          showAlert(context, 'Something went wrong, please try again');
                        }
                        setState(() {});
                      },
                      child: Text(
                        "Create",
                        style: TextStyle(
                          color: Theme.of(context).highlightColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: questionInput,
              ),
              Divider(
                thickness: 1.0,
              ),
              GestureDetector(
                onTap: () async {
                  String selected = await showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext context) => CategorySearchSelect());

                  if (selected != null) {
                    setState(() {
                      selectedCategory = selected;
                    });
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
                            "Select Category",
                            style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
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
                child: selectedCategory != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                        child: Text(selectedCategory),
                      )
                    : Container(),
              ),
              Divider(
                thickness: 1.0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 18.0),
                child: Container(
                  child: GestureDetector(
                    onTap: loadAssets,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Add Images",
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1.0, left: 5.0),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 20.0,
                          ),
                        ),
                      ],
                    ),
                  ),
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

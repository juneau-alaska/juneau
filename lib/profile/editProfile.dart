import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/userMethods.dart';
import 'package:juneau/common/components/inputComponent.dart';
import 'package:juneau/common/methods/validator.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileModal extends StatefulWidget {
  final user;

  EditProfileModal({Key key, @required this.user}) : super(key: key);

  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  BuildContext editProfileContext;

  var user;
  var profilePhoto;
  String profilePhotoUrl;

  InputComponent usernameInput;
  TextEditingController usernameController;

  InputComponent emailInput;
  TextEditingController emailController;

  InputComponent descriptionInput;
  TextEditingController descriptionController;

  bool _isEmailValid = false;
  bool _isUsernameValid = false;
  bool profileFetched = false;

  Future updateUserInfo(updatedInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/user/' + userId;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode(updatedInfo);
    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
      if (msg == null) {
        msg = 'Something went wrong, please try again';
      }
      showAlert(editProfileContext, msg);
      return null;
    }
  }

  @override
  void initState() {
    user = widget.user;

    usernameInput = new InputComponent(
      hintText: 'Username',
      inputFormatters: [FilteringTextInputFormatter.allow(new RegExp("[0-9A-Za-z_.]"))],
    );
    usernameController = usernameInput.controller;
    usernameController.text = user['username'];

    emailInput = new InputComponent(hintText: 'Email');
    emailController = emailInput.controller;
    emailController.text = user['email'];

    descriptionInput = new InputComponent(
      hintText: 'Description',
      maxLength: 150,
    );
    descriptionController = descriptionInput.controller;
    descriptionController.text = user['description'];

    profilePhotoUrl = user['profilePhoto'];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (profilePhoto == null && profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }
      profileFetched = true;

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    editProfileContext = context;

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          toolbarHeight: 80.0,
          backgroundColor: Theme.of(context).backgroundColor,
          brightness: Theme.of(context).brightness,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 25.0,
                color: Theme.of(context).buttonColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Column(
                    children: [
                      profilePhoto != null
                        ? Container(
                        width: 80,
                        height: 80,
                        child: ClipOval(
                          child: Image.memory(
                            profilePhoto,
                            fit: BoxFit.cover,
                            width: 80.0,
                            height: 80.0,
                          ),
                        ),
                      )
                        : CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.transparent,
                        backgroundImage: profileFetched ? AssetImage('images/profile.png') : null,
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          // OPEN MULTI SELECT
                          List selectedImages = await MultiImagePicker.pickImages(
                            maxImages: 1,
                            enableCamera: true,
                            selectedAssets: [],
                          );

                          var selectedImage = selectedImages[0];

                          // CREATE URLS
                          String path = await FlutterAbsolutePath.getAbsolutePath(
                            selectedImage.identifier);

                          final file = File(path);
                          if (!file.existsSync()) {
                            file.createSync(recursive: true);
                          }

                          String fileExtension = p.extension(file.path);
                          var imageUrl = await imageMethods
                            .getImageUrl(fileExtension, 'user-profile')
                            .catchError((err) {
                            showAlert(context, 'Something went wrong, please try again');
                          });

                          // UPLOAD IMAGE
                          if (imageUrl != null) {
                            String uploadUrl = imageUrl['uploadUrl'];
                            String downloadUrl = imageUrl['downloadUrl'];

                            await imageMethods
                              .uploadFile(uploadUrl, selectedImage)
                              .then((result) async {
                              String prevUrl = profilePhotoUrl;
                              // SAVE LINK TO USER
                              var updatedUser =
                              await userMethods.updateUser(user['_id'], {
                                'profilePhoto': downloadUrl,
                              });

                              if (updatedUser == null) {
                                showAlert(
                                  context, 'Something went wrong, please try again');
                                return;
                              }

                              // DELETE PREVIOUS IMAGE
                              if (prevUrl != null && prevUrl != '') {
                                imageMethods.deleteFile(prevUrl, 'user-profile');
                                user = updatedUser;
                                profilePhotoUrl = updatedUser['profilePhoto'];
                              }
                            }).catchError((err) {
                              showAlert(
                                context, 'Something went wrong, please try again');
                            });
                          }

                          // SHOW NEW PROFILE IMAGE
                          setState(() {
                            showAlert(editProfileContext, 'Successfully saved profile photo', true);
                          });
                        },
                        child: Text(
                          'Change Profile Photo',
                          style: TextStyle(
                            color: Theme.of(context).highlightColor,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'USERNAME',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              usernameInput,
              SizedBox(height: 18),
              Text(
                'EMAIL',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              emailInput,
              SizedBox(height: 18),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              descriptionInput,
              SizedBox(height: 13),
              RawMaterialButton(
                onPressed: () async {
                  if (user == null) {
                    return;
                  }

                  String username = usernameController.text.trim();
                  String email = emailController.text.trim();
                  String description = descriptionController.text.trim();

                  var updatedInfo = {};

                  if (username != '' && username != user['username']) {
                    _isUsernameValid = validator.validateUsername(username);

                    if (!_isUsernameValid) {
                      return showAlert(context, 'Username contains invalid characters.');
                    }

                    updatedInfo['username'] = username;
                  }

                  if (email != '' && email != user['email']) {
                    _isEmailValid = EmailValidator.validate(email);

                    if (!_isEmailValid) {
                      return showAlert(context, 'Invalid email address.');
                    }

                    updatedInfo['email'] = email;
                  }

                  if (description == '') {
                    description = null;
                  }
                  updatedInfo['description'] = description;

                  user = await updateUserInfo(updatedInfo);
                  if (user != null) {
                    Navigator.pop(context, user);
                  }
                },
                constraints: BoxConstraints(),
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                fillColor: Theme.of(context).buttonColor,
                elevation: 0.0,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Theme.of(context).backgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: Theme.of(context).backgroundColor,
                        width: 1,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(5)),
              ),
            ],
          ),
        ));
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:juneau/common/api.dart';

import 'package:juneau/comment/commentsPage.dart';
import 'package:juneau/common/components/alertComponent.dart';
import 'package:juneau/common/components/keepAlivePage.dart';
import 'package:juneau/common/components/pageRoutes.dart';
import 'package:juneau/common/components/pollListPopover.dart';
import 'package:juneau/common/methods/imageMethods.dart';
import 'package:juneau/common/methods/notificationMethods.dart';
import 'package:juneau/common/methods/pollMethods.dart';
import 'package:juneau/poll/pollPreview.dart';
import 'package:juneau/profile/editProfile.dart';
import 'package:juneau/settings/accountSettings.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

void openProfile(context, profileUser, {user}) {
  Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          toolbarHeight: 40.0,
          backgroundColor: Theme.of(context).backgroundColor,
          brightness: Theme.of(context).brightness,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 25.0,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ProfilePage(profileUser: profileUser, user: user),
    );
  }));
}

class ProfilePage extends StatefulWidget {
  final profileUser;
  final user;
  final profilePhoto;
  final profileController;

  ProfilePage({
    Key key,
    @required this.profileUser,
    this.user,
    this.profilePhoto,
    this.profileController,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var profileUser;
  var user;
  var profilePhoto;
  String profilePhotoUrl;
  String profileUserId;
  String userId;
  String prevId;
  Widget gridListView;
  List pollObjects;
  BuildContext profileContext;

  bool pollOpen = false;
  bool preventReload = false;
  bool following = false;
  bool profileFetched = false;
  bool isUser = false;

  bool alreadyPressed = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);
  StreamController pollListController = StreamController.broadcast();
  var parentController;

  Future fetchPollData(bool next) async {
    List polls = await pollMethods.getPollsFromUser(profileUserId);

    if (pollObjects == null ||
        (next && polls.length > 0) ||
        (!next && polls.length != pollObjects.length)) {
      if (!next) {
        pollObjects = [];
      }
      for (int i = 0; i < polls.length; i++) {
        var poll = polls[i];
        pollObjects.add({
          'index': i,
          'poll': poll,
        });
      }
      setState(() {
        preventReload = false;
      });
    }
  }

  @override
  void initState() {
    profileUser = widget.profileUser;
    user = widget.user;
    prevId = null;
    parentController = new StreamController.broadcast();

    profilePhotoUrl = profileUser['profilePhoto'];
    profilePhoto = widget.profilePhoto;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      profileUserId = profileUser['_id'];

      if (user != null) {
        userId = user['_id'];
        following = user['followingUsers'].contains(profileUserId);
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
      }
      isUser = userId == profileUserId;

      if (profilePhoto == null && profilePhotoUrl != null) {
        profilePhoto = await imageMethods.getImage(profilePhotoUrl);
      }
      profileFetched = true;

      await fetchPollData(false);
    });

    super.initState();
  }

  Widget createGridList() {
    List<Widget> pollsList = [];
    List<Widget> gridRow = [];

    for (int i = 0; i < pollObjects.length; i++) {
      var pollObject = pollObjects[i];
      var padding = const EdgeInsets.all(0.0);

      if (i % 3 == 0) {
        padding = const EdgeInsets.only(right: 1.0);
      } else if (i % 3 == 2) {
        padding = const EdgeInsets.only(left: 1.0);
      }

      gridRow.add(Hero(
        tag: pollObject['poll']['_id'],
        child: Padding(
          padding: padding,
          child: PollPreview(
            pollObject: pollObject,
            openListView: openListView,
          ),
        ),
      ));

      if ((i + 1) % 3 == 0 || i == pollObjects.length - 1) {
        pollsList.add(
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gridRow),
        );
        gridRow = [];
      }
    }

    return Column(
      children: pollsList,
    );
  }

  @override
  void dispose() {
    refreshController.dispose();
    pollListController.close();
    parentController.close();
    super.dispose();
  }

  void updatedUserModel(updatedUser) {
    profileUser = updatedUser;
    parentController.add({'dataType': 'user', 'data': profileUser});
  }

  void dismissPoll(index) {
    if (mounted) {
      setState(() {
        preventReload = false;
        pollObjects.removeAt(index);
        pollListController.add(pollObjects);
      });
    }
  }

  void viewPoll(String pollId) async {
    if (!pollOpen) {
      pollOpen = true;
      final _formKey = GlobalKey<FormState>();

      Navigator.of(profileContext).push(TransparentRoute(builder: (BuildContext context) {
        return CommentsPage(user: profileUser, pollId: pollId, formKey: _formKey);
      }));

      pollOpen = false;
    }
  }

  Future<void> _onRefresh() async {
    prevId = null;
    await fetchPollData(false);
    refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    if (pollObjects.length == profileUser['createdPolls'].length) return;
    await fetchPollData(true);
    refreshController.refreshCompleted();
  }

  void openListView(index, tag) async {
    Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {
      return PollListPopover(
          selectedIndex: index,
          user: profileUser,
          title: profileUser['username'],
          pollObjects: pollObjects,
          pollListController: pollListController,
          dismissPoll: dismissPoll,
          viewPoll: viewPoll,
          updatedUserModel: updatedUserModel,
          parentController: parentController,
          tag: tag,
      );
    }));
  }

  Future updateUser(followingUsers, follow) async {
    String url = API_URL + 'user/' + userId;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    };

    var body = jsonEncode({'followingUsers': followingUsers});

    var response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      if (follow) {
        notificationMethods.createNotification(userId, profileUser['_id'], 'started following you.');
      }
      return jsonDecode(response.body);
    } else {
      var jsonResponse = jsonDecode(response.body), msg = jsonResponse['msg'];
      if (msg == null) {
        msg = 'Something went wrong, please try again';
      }
      showAlert(profileContext, msg);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pollObjects != null && !preventReload) {
      preventReload = true;
      profileContext = context;
      gridListView = createGridList();
    }

    return KeepAlivePage(
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
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: isUser
                        ? const EdgeInsets.symmetric(vertical: 10.0)
                        : const EdgeInsets.only(top: 5.0, bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        profilePhoto != null
                          ? Container(
                          width: 40,
                          height: 40,
                          child: ClipOval(
                            child: Image.memory(
                              profilePhoto,
                              fit: BoxFit.cover,
                              width: 40.0,
                              height: 40.0,
                            ),
                          ),
                        )
                          : CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          backgroundImage: profileFetched ? AssetImage('images/profile.png') : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            profileUser['username'],
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  profileUser['description'] != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            profileUser['description'],
                          ),
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: isUser != null && isUser
                          ? [
                              RawMaterialButton(
                                onPressed: () async {
                                  var update = await showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return new EditProfileModal(
                                          user: profileUser,
                                        );
                                      });

                                  setState(() {
                                    if (update != null) {
                                      profileUser = update['user'];
                                      profilePhoto = update['profilePhoto'];
                                      widget.profileController.add(profilePhoto);
                                    }
                                  });
                                },
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                                fillColor: Theme.of(context).backgroundColor,
                                elevation: 0.0,
                                child: Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Theme.of(context).hintColor,
                                        width: 0.5,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                              SizedBox(width: 5.0),
                              RawMaterialButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AccountSettings(user: profileUser));
                                },
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                                fillColor: Theme.of(context).backgroundColor,
                                elevation: 0.0,
                                child: Text(
                                  'Settings',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Theme.of(context).hintColor,
                                        width: 0.5,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                            ]
                          : [
                              RawMaterialButton(
                                onPressed: () async {
                                  if (!alreadyPressed) {
                                    alreadyPressed = true;
                                  } else {
                                    return showAlert(profileContext, 'Going too fast.');
                                  }

                                  List followingUsers =
                                      user['followingUsers'] != null ? user['followingUsers'] : [];
                                  String profileUserId = profileUser['_id'];

                                  if (following) {
                                    followingUsers.remove(profileUserId);
                                  } else {
                                    followingUsers.add(profileUserId);
                                  }

                                  var updatedUser = await updateUser(followingUsers, !following);
                                  if (updatedUser != null) {
                                    setState(() {
                                      user = updatedUser;
                                      following = followingUsers.contains(profileUserId);
                                      alreadyPressed = false;
                                    });
                                  }
                                },
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                                fillColor: following
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).backgroundColor,
                                elevation: 0.0,
                                child: Text(
                                  following ? 'Unfollow' : 'Follow',
                                  style: TextStyle(
                                    color: following
                                        ? Theme.of(context).backgroundColor
                                        : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 0.5,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
            pollObjects != null
                ? pollObjects.length > 0
                    ? gridListView
                    : Padding(
                        padding: const EdgeInsets.only(top: 100.0),
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
        ),
      ),
    );
  }
}

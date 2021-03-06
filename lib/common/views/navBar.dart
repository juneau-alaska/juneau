import 'package:flutter/material.dart';
import 'package:juneau/common/colors.dart';
import 'package:juneau/poll/pollCreate.dart';

class NavBar extends StatefulWidget {
  final navigatorKey;
  final navController;
  final profilePhoto;
  final profileController;

  NavBar({
    Key key,
    @required this.navigatorKey,
    this.navController,
    this.profilePhoto,
    this.profileController,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _previousIndex = 0;
  int _selectedIndex = 0;
  var profilePhoto;

  @override
  void initState() {
    profilePhoto = widget.profilePhoto;

    widget.profileController.stream.listen((updatedProfilePhoto) {
      profilePhoto = updatedProfilePhoto;
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 87.5,
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0.0,
          backgroundColor: Theme.of(context).backgroundColor,
          unselectedItemColor: customColors.darkGrey,
          selectedItemColor: Theme.of(context).primaryColor,
          selectedFontSize: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
              switch (index) {
                case 0:
                  _previousIndex = _selectedIndex;
                  widget.navController.add(0);
                  break;
                case 1:
                  _previousIndex = _selectedIndex;
                  widget.navController.add(1);
                  break;
                case 2:
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext context) {
                        return new PollCreate();
                      });
                  _selectedIndex = _previousIndex;
                  break;
                case 3:
                  break;
                case 4:
                  _previousIndex = _selectedIndex;
                  widget.navController.add(2);
                  break;
                default:
                  break;
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home_outlined, size: 32.0),
              activeIcon: new Icon(Icons.home, size: 32.0),
              title: Text(''),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.search, size: 30.0),
              title: Text(''),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.add, size: 30.0),
              title: Text(''),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.notifications_outlined, size: 30.0),
              activeIcon: new Icon(Icons.notifications, size: 30.0),
              title: Text(''),
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: customColors.darkGrey,
                child: profilePhoto != null
                  ? Container(
                  width: 28,
                  height: 28,
                  child: ClipOval(
                    child: Image.memory(
                      profilePhoto,
                      fit: BoxFit.cover,
                      width: 28.0,
                      height: 28.0,
                    ),
                  ),
                )
                  : CircleAvatar(
                  radius: 11.5,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('images/profile.png'),
                ),
              ),
              activeIcon: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).primaryColor,
                child: profilePhoto != null
                    ? Container(
                        width: 28,
                        height: 28,
                        child: ClipOval(
                          child: Image.memory(
                            profilePhoto,
                            fit: BoxFit.cover,
                            width: 28.0,
                            height: 28.0,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 11.5,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage('images/profile.png'),
                      ),
              ),
              title: Text(''),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:juneau/poll/pollCreate.dart';

class NavBar extends StatefulWidget {
  final navigatorKey;
  final navController;

  NavBar({Key key,
    @required this.navigatorKey,
    this.navController,
  })
    : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _previousIndex = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0.0,
          backgroundColor: Theme
            .of(context)
            .backgroundColor,
          unselectedItemColor: Theme
            .of(context)
            .hintColor,
          selectedItemColor: Theme
            .of(context)
            .buttonColor,
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
                  _previousIndex = _selectedIndex;
                  widget.navController.add(1);
                  break;
                default:
                  break;
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: new Icon(
                Icons.home,
                size: 28.0
              ),
              title: Text(''),
            ),

            BottomNavigationBarItem(
              icon: new Icon(
                Icons.search,
                size: 28.0
              ),

              title: Text(''),
            ),

            BottomNavigationBarItem(
              icon: new Icon(
                Icons.add,
                size: 28.0
              ),
              title: Text(''),
            ),

            BottomNavigationBarItem(
              icon: new Icon(
                Icons.account_circle,
                size: 28.0
              ),

              title: Text(''),
            ),
          ],
        ),
      ),
    );
  }
}

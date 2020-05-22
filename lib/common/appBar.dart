import 'package:flutter/material.dart';

Widget appBar() {
  return _AppBar(height: 50.0);
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const _AppBar({
    Key key,
    @required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: new Container(),
      title: Text(
        'JUNEAU',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
      elevation: 0.0,
      centerTitle: true,
      backgroundColor: Theme.of(context).cardColor,
      brightness: Brightness.dark,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(height),
        child: Container(
          decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 0.5,
                color: Theme.of(context).cardColor // Theme.of(context).accentColor
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
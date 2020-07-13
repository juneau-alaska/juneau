import 'package:flutter/material.dart';

Widget appBar() {
  return _AppBar(height: 30.0);
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
//      title: Text(
//        'JUNEAU',
//        style: TextStyle(
//          color: Theme.of(context).textTheme.bodyText1.color,
//          fontSize: 20,
//          fontWeight: FontWeight.bold
//        ),
//      ),
      elevation: 0.0,
      centerTitle: true,
      backgroundColor: Theme.of(context).cardColor,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(height),
        child: Container(
          decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 0.5,
                color: Theme.of(context).cardColor
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
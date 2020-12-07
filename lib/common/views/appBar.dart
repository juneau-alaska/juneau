import 'package:flutter/material.dart';

class ApplicationBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const ApplicationBar({
    Key key,
    @required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: new Container(),
      elevation: 0.0,
      centerTitle: true,
      backgroundColor: Theme.of(context).backgroundColor,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

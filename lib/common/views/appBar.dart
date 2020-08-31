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
      elevation: 0.0,
      centerTitle: true,
      backgroundColor: Theme.of(context).backgroundColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

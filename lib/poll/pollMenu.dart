import 'package:flutter/material.dart';

class PollMenu extends StatefulWidget {
  final isCreator;

  PollMenu({
    Key key,
    @required this.isCreator,
  }) : super(key: key);

  @override
  _PollMenuState createState() => _PollMenuState();
}

class _PollMenuState extends State<PollMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 40.0),
        decoration: new BoxDecoration(
          borderRadius: new BorderRadius.circular(8.0),
          color: Theme.of(context).backgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: widget.isCreator ? [
            GestureDetector(
              onTap: () {
                Navigator.pop(context, 'delete');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
                child: Container(
                  child: Row(children: [
                    Icon(Icons.delete, size: 25.0),
                    SizedBox(
                      width: 13.0,
                    ),
                    Text('Delete')
                  ])),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 14.0),
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.circular(50.0),
                  color: Theme.of(context).buttonColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13.0),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).backgroundColor
                      ),
                    ),
                  ),
                ),
              ),
            )
          ] : [
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
                child: Container(
                  child: Row(children: [
                    Icon(Icons.flag, size: 25.0, color: Colors.red),
                    SizedBox(
                      width: 13.0,
                    ),
                    Text('Report', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300, color: Colors.red))
                  ])),
              ),
            ),
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
                child: Container(
                  child: Row(children: [
                    Icon(Icons.bookmark, size: 25.0),
                    SizedBox(
                      width: 13.0,
                    ),
                    Text('Save', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300))
                  ])),
              ),
            ),
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 14.0),
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.circular(8.0),
                  color: Theme.of(context).highlightColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13.0),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13.0, fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
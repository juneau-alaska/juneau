import 'package:flutter/material.dart';
import 'package:juneau/common/components/pageRoutes.dart';

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(TransparentRoute(builder: (BuildContext context) {

                    return Scaffold(
                      backgroundColor: Theme.of(context).backgroundColor,
                      appBar: AppBar(
                        toolbarHeight: 30.0,
                        backgroundColor: Theme.of(context).backgroundColor,
                        brightness: Theme.of(context).brightness,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: 25.0,
                            color: Theme.of(context).buttonColor,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        height: 100,
                        width: 100,
                        color: Colors.red,
                      ),
                    );
                  }));
                },
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).buttonColor
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            children: [

            ],
          ),
        ),
      ],
    );
  }
}

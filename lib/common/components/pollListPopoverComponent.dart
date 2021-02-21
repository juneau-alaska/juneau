import 'package:flutter/material.dart';
import 'package:juneau/poll/poll.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PollListPopover extends StatefulWidget {
  final selectedIndex;
  final user;
  final title;
  final pollObjects;
  final pollListController;
  final dismissPoll;
  final viewPoll;
  final updatedUserModel;
  final parentController;
  final tag;

  PollListPopover({
    Key key,
    @required this.selectedIndex,
    this.user,
    this.title,
    this.pollObjects,
    this.pollListController,
    this.dismissPoll,
    this.viewPoll,
    this.updatedUserModel,
    this.parentController,
    this.tag,
  }) : super(key: key);

  @override
  _PollListPopoverState createState() => _PollListPopoverState();
}

class _PollListPopoverState extends State<PollListPopover> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  List<Widget> pollsList;
  List pollObjects;
  int visibleIndex;

  @override
  void initState() {
    pollObjects = widget.pollObjects;

    widget.pollListController.stream.listen((updatedPollObjects) {
      setState(() {
        pollObjects = updatedPollObjects;
      });
    });

    if (widget.selectedIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        itemScrollController.jumpTo(index: widget.selectedIndex);
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.tag != null
            ? Center(
                child: Hero(
                    tag: widget.tag,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                    )),
              )
            : Container(),
        Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
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
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).buttonColor,
              ),
            ),
          ),
          body: pollObjects != null && pollObjects.length > 0
              ? ScrollablePositionedList.builder(
                  itemCount: pollObjects.length + 1,
                  itemBuilder: (context, index) {
                    if (index == pollObjects.length) {
                      return SizedBox(height: 43);
                    }

                    var pollObject = pollObjects[index],
                        poll = pollObject['poll'] != null ? pollObject['poll'] : pollObject,
                        options = pollObject['options'],
                        images = pollObject['images'];

                    return Container(
                      key: UniqueKey(),
                      child: PollWidget(
                          poll: poll,
                          options: options,
                          images: images,
                          user: widget.user,
                          dismissPoll: widget.dismissPoll,
                          viewPoll: widget.viewPoll,
                          index: index,
                          updatedUserModel: widget.updatedUserModel,
                          parentController: widget.parentController),
                    );
                  },
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                )
              : Center(
                  child: Container(
                    child: Text('No created polls found'),
                  ),
                ),
        ),
      ],
    );
  }
}

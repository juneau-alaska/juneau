import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  final maxLines;
  final borderColor;
  final padding;
  final controller = TextEditingController();

  InputComponent({
    Key key,
    @required
      this.hintText,
      this.errorText,
      this.obscureText,
      this.maxLines,
      this.borderColor,
      this.padding,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    var padding = widget.padding != null ? EdgeInsets.all(widget.padding) : EdgeInsets.all(11.0);
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
        child: Container(
          child: TextField(
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: padding,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(context).accentColor,
              ),
              fillColor: Theme.of(context).dialogBackgroundColor,
              filled: true,
              errorText: widget.errorText,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).accentColor,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).accentColor,
                  width: 0.5,
                ),
              ),
            ),
            controller: widget.controller,
          ),
        ),
      ),
    );
  }
}
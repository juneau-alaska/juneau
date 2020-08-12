import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  int maxLines;
  final borderColor;
  final padding;
  double fontSize;
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
      this.fontSize,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    var edgeInset = widget.padding != null ? EdgeInsets.all(widget.padding) : EdgeInsets.fromLTRB(11.0, 12.0, 11.0, 12.0);
    widget.maxLines = widget.maxLines != null ? widget.maxLines : 1;
    widget.fontSize = widget.fontSize != null ? widget.fontSize: 14.0;
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
        child: Container(
          child: TextField(
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            style: TextStyle(
              color: const Color(0xFFD7DADC),
              fontSize: widget.fontSize,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: edgeInset,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w300
              ),
              fillColor: Theme.of(context).primaryColor,
              filled: true,
              errorText: widget.errorText,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).hintColor,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).hintColor,
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
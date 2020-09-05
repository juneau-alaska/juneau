import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  final maxLines;
  final borderColor;
  final padding;
  final fontSize;
  final controller = TextEditingController();

  InputComponent({
    Key key,
    @required this.hintText,
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
    EdgeInsets edgeInset =
        widget.padding != null ? EdgeInsets.all(widget.padding) : EdgeInsets.fromLTRB(11.0, 13.0, 11.0, 13.0);
    int maxLines = widget.maxLines != null ? widget.maxLines : 1;
    double fontSize = widget.fontSize != null ? widget.fontSize : 14.0;
    bool obscureText = widget.obscureText != null ? widget.obscureText : false;

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
        child: Container(
          child: TextField(
            obscuringCharacter: '•',
            obscureText: obscureText,
            maxLines: maxLines,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: edgeInset,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w400),
              fillColor: Theme.of(context).backgroundColor,
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

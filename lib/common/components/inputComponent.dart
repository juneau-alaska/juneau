import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  final maxLines;
  final borderColor;
  final padding;
  final contentPadding;
  final fontSize;
  final fontWeight;
  final autoFocus;
  final prefixIcon;
  final controller = TextEditingController();

  InputComponent({
    Key key,
    @required this.hintText,
    this.errorText,
    this.obscureText,
    this.maxLines,
    this.borderColor,
    this.padding,
    this.contentPadding,
    this.fontSize,
    this.fontWeight,
    this.autoFocus,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    EdgeInsets contentPadding = widget.contentPadding == null ? EdgeInsets.all(12.0) : widget.contentPadding;
    int maxLines = widget.maxLines == null ? 1 : widget.maxLines;
    double fontSize = widget.fontSize == null ? 15.0 : widget.fontSize;
    bool obscureText = widget.obscureText == null ? false : widget.obscureText;
    Color borderColor = widget.borderColor == null ? Theme.of(context).hintColor : widget.borderColor;
    FontWeight fontWeight = widget.fontWeight == null ? FontWeight.w500 : widget.fontWeight;
    bool autoFocus = widget.autoFocus == null ? false : widget.autoFocus;
    EdgeInsets padding = widget.padding == null ? EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0) : widget.padding;

    OutlineInputBorder borderOutline = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: borderColor,
          width: 0.5,
        ));

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: padding,
        child: Container(
          child: TextField(
            obscuringCharacter: '•',
            obscureText: obscureText,
            maxLines: maxLines,
            autofocus: autoFocus,
            style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
            decoration: InputDecoration(
                prefixIcon: widget.prefixIcon,
                isDense: true,
                contentPadding: contentPadding,
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Theme.of(context).hintColor, fontWeight: fontWeight, fontFamily: 'Lato Regular'),
                filled: false,
                errorText: widget.errorText,
                focusedBorder: borderOutline,
                enabledBorder: borderOutline),
            controller: widget.controller,
          ),
        ),
      ),
    );
  }
}

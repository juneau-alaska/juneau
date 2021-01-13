import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  final maxLines;
  final maxLength;
  final borderColor;
  final contentPadding;
  final fontSize;
  final fontWeight;
  final autoFocus;
  final prefixIcon;
  final inputFormatters;
  final controller = TextEditingController();

  InputComponent({
    Key key,
    @required this.hintText,
    this.errorText,
    this.obscureText,
    this.maxLines,
    this.maxLength,
    this.borderColor,
    this.contentPadding,
    this.fontSize,
    this.fontWeight,
    this.autoFocus,
    this.prefixIcon,
    this.inputFormatters,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    EdgeInsets contentPadding = widget.contentPadding == null ? EdgeInsets.symmetric(vertical: 15.0, horizontal: 0.0) : widget.contentPadding;
    int maxLines = widget.maxLines == null ? 1 : widget.maxLines;
    double fontSize = widget.fontSize == null ? 15.0 : widget.fontSize;
    bool obscureText = widget.obscureText == null ? false : widget.obscureText;
    Color borderColor = widget.borderColor == null ? Theme.of(context).hintColor : widget.borderColor;
    FontWeight fontWeight = widget.fontWeight == null ? FontWeight.w300 : widget.fontWeight;
    bool autoFocus = widget.autoFocus == null ? false : widget.autoFocus;
    List<TextInputFormatter> inputFormatters = widget.inputFormatters == null ? [] : widget.inputFormatters;

    UnderlineInputBorder borderOutline = UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor,
        width: 0.5
      )
    );

    return Container(
      color: Colors.transparent,
      child: TextField(
        obscuringCharacter: '•',
        obscureText: obscureText,
        maxLines: maxLines,
        maxLength: widget.maxLength,
        autofocus: autoFocus,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        decoration: InputDecoration(
            prefixIcon: widget.prefixIcon,
            counterText: "",
            isDense: true,
            contentPadding: contentPadding,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Theme.of(context).hintColor, fontWeight: fontWeight),
            filled: false,
            errorText: widget.errorText,
            focusedBorder: borderOutline,
            enabledBorder: borderOutline,
        ),
        controller: widget.controller,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  int maxLines;
  final borderColor;
  final padding;
  final capitalize;
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
      this.capitalize,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    var edgeInset = widget.padding != null ? EdgeInsets.all(widget.padding) : EdgeInsets.fromLTRB(11.0, 12.0, 11.0, 12.0);
    TextCapitalization capitalize = widget.capitalize != null && widget.capitalize ? TextCapitalization.characters : TextCapitalization.none;
    widget.maxLines = widget.maxLines != null ? widget.maxLines : 1;
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
        child: Container(
          child: TextField(
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            textCapitalization: capitalize,
            style: TextStyle(
              color: const Color(0xFFD7DADC),
              fontSize: 14.0,
              fontFamily: 'Lato Regular',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: edgeInset,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w300
              ),
              fillColor: Theme.of(context).primaryColor,
              filled: true,
              errorText: widget.errorText,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).cardColor,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor != null ? widget.borderColor : Theme.of(context).cardColor,
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
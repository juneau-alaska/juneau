import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final hintText;
  final errorText;
  final obscureText;
  final controller = TextEditingController();

  InputComponent({
    Key key,
    @required
      this.hintText,
      this.errorText,
      this.obscureText,
  }) : super(key: key);

  @override
  _InputComponentState createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
        child: Container(
          child: TextField(
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(11.0),
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
                color: Theme.of(context).accentColor,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: Theme.of(context).accentColor, // Colors.white30,
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
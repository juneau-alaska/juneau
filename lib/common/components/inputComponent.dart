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
          height: 45.0,
          child: Opacity(
            opacity: 0.8,
            child: TextField(
              obscureText: widget.obscureText,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(fontSize: 14, color: Colors.white70),
                fillColor: Colors.white10,
                filled: true,
                errorText: widget.errorText,
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30, width: 1.0),
                ),
              ),
              controller: widget.controller,
            ),
          ),
        ),
      ),
    );
  }
}
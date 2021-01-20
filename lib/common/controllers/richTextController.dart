import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//    REGEX MATCHING EXAMPLES:
//    RegExp(r"\B@[a-zA-Z0-9]+\b"):TextStyle(), <--- @
//    RegExp(r"\B#[a-zA-Z0-9]+\b"):TextStyle(), <--- #
//    RegExp(r"\B![a-zA-Z0-9]+\b"):TextStyle(), <--- !

class RichTextController extends TextEditingController {
  final Map<RegExp, TextStyle> patternMap;

  RichTextController(this.patternMap) : assert(patternMap != null);

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    List<TextSpan> children = [];
    RegExp allRegex;
    allRegex = RegExp(patternMap.keys.map((e) => e.pattern).join('|'));
    text.splitMapJoin(
      allRegex,
      onMatch: (Match m) {
        RegExp k = patternMap.entries.firstWhere((element) {
          return element.key.allMatches(m[0]).isNotEmpty;
        }).key;
        children.add(
          TextSpan(
            text: m[0],
            style: patternMap[k],
          ),
        );
        return m[0];
      },
      onNonMatch: (String span) {
        children.add(TextSpan(text: span, style: style));
        return span.toString();
      },
    );
    return TextSpan(style: style, children: children);
  }
}

import 'package:flutter/widgets.dart';

abstract final class TextMeasure {
  static double width(
    BuildContext context,
    String text,
    TextStyle? style, {
    bool longestWord = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    try {
      return longestWord
          ? painter.minIntrinsicWidth
          : painter.maxIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }
}

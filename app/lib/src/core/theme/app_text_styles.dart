import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const TextStyle tabularFigures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const double _heroLetterSpacing = -0.45;

  static TextStyle? heroAmount(TextTheme textTheme) =>
      textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: _heroLetterSpacing,
      );

  static TextStyle? strong(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w600);

  static TextStyle? medium(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w500);
}

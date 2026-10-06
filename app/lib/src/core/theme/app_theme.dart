import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF00AFCA);

  static final ThemeData light = _themeFor(Brightness.light);
  static final ThemeData dark = _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) =>
      ThemeData(colorSchemeSeed: _seed, brightness: brightness);
}

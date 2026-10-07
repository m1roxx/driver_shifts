import 'package:flutter/widgets.dart';

abstract final class TextScale {
  static const double largeFrom = 1.5;
  static const double headlineMax = 1.6;
  static const double _probe = 16;

  static bool isLarge(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_probe) / _probe >= largeFrom;

  static TextScaler headline(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: headlineMax);
}

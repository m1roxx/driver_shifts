import 'package:flutter/animation.dart';

abstract final class Motion {
  static const Curve curve = Curves.easeOutCubic;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration resize = Duration(milliseconds: 200);
  static const Duration swipeBack = Duration(milliseconds: 200);
  static const Duration daySwitch = Duration(milliseconds: 250);
  static const Duration reduced = Duration(milliseconds: 100);
  static const Duration skeletonDelay = Duration(milliseconds: 300);
  static const Duration skeletonPulse = Duration(milliseconds: 900);
  static const Duration newTripHighlight = Duration(milliseconds: 1200);

  static const double dayShift = 24;
  static const double swipeCommitFraction = 0.3;
}

abstract final class Opacities {
  static const double locked = 0.5;
  static const double skeletonDimmed = 0.55;
}

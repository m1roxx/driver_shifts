import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppIcons {
  material(
    previousDay: Icons.chevron_left,
    nextDay: Icons.chevron_right,
    dayArrowSize: 28,
    expand: Icons.expand_more,
    close: Icons.close,
    add: Icons.add,
    date: Icons.event_outlined,
    time: Icons.schedule,
    error: Icons.error_outline,
    offline: Icons.cloud_off_outlined,
    emptyDay: Icons.event_busy_outlined,
    retry: Icons.refresh,
    waiting: Icons.hourglass_empty_rounded,
  ),
  cupertino(
    previousDay: CupertinoIcons.chevron_left,
    nextDay: CupertinoIcons.chevron_right,
    dayArrowSize: 24,
    expand: CupertinoIcons.chevron_down,
    close: CupertinoIcons.xmark,
    add: CupertinoIcons.add,
    date: CupertinoIcons.calendar,
    time: CupertinoIcons.clock,
    error: CupertinoIcons.exclamationmark_circle,
    offline: CupertinoIcons.wifi_slash,
    emptyDay: CupertinoIcons.calendar_badge_minus,
    retry: CupertinoIcons.arrow_clockwise,
    waiting: CupertinoIcons.hourglass,
  );

  const AppIcons({
    required this.previousDay,
    required this.nextDay,
    required this.dayArrowSize,
    required this.expand,
    required this.close,
    required this.add,
    required this.date,
    required this.time,
    required this.error,
    required this.offline,
    required this.emptyDay,
    required this.retry,
    required this.waiting,
  });

  static const IconData cash = Icons.payments_rounded;
  static const IconData card = Icons.credit_card_rounded;

  static AppIcons of(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => cupertino,
        TargetPlatform.android ||
        TargetPlatform.fuchsia ||
        TargetPlatform.linux ||
        TargetPlatform.windows => material,
      };

  final IconData previousDay;
  final IconData nextDay;
  final double dayArrowSize;
  final IconData expand;
  final IconData close;
  final IconData add;
  final IconData date;
  final IconData time;
  final IconData error;
  final IconData offline;
  final IconData emptyDay;
  final IconData retry;
  final IconData waiting;
}

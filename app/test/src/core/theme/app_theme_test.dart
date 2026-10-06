import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the theme for the platform the app runs on', () {
    expect(AppTheme.light.platform, TargetPlatform.android);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(AppTheme.light.platform, TargetPlatform.iOS);
    expect(AppTheme.dark.platform, TargetPlatform.iOS);
  });
}

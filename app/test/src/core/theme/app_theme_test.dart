import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:driver_shifts/src/core/theme/payment_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Color> _roles(ColorScheme colors) => {
  'primary': colors.primary,
  'onPrimary': colors.onPrimary,
  'primaryContainer': colors.primaryContainer,
  'onPrimaryContainer': colors.onPrimaryContainer,
  'secondaryContainer': colors.secondaryContainer,
  'onSecondaryContainer': colors.onSecondaryContainer,
  'surface': colors.surface,
  'surfaceContainerLowest': colors.surfaceContainerLowest,
  'surfaceContainerLow': colors.surfaceContainerLow,
  'surfaceContainer': colors.surfaceContainer,
  'surfaceContainerHigh': colors.surfaceContainerHigh,
  'surfaceContainerHighest': colors.surfaceContainerHighest,
  'onSurface': colors.onSurface,
  'onSurfaceVariant': colors.onSurfaceVariant,
  'outline': colors.outline,
  'outlineVariant': colors.outlineVariant,
  'error': colors.error,
  'errorContainer': colors.errorContainer,
  'onErrorContainer': colors.onErrorContainer,
};

Map<String, Color> _payment(PaymentColors colors) => {
  'cashContainer': colors.cashContainer,
  'onCashContainer': colors.onCashContainer,
  'cardContainer': colors.cardContainer,
  'onCardContainer': colors.onCardContainer,
};

Map<String, String> _hex(Map<String, Color> colors) => {
  for (final MapEntry(:key, :value) in colors.entries)
    key: '#${(value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase(),
};

void main() {
  test('builds the theme for the platform the app runs on', () {
    expect(AppTheme.light.platform, TargetPlatform.android);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(AppTheme.light.platform, TargetPlatform.iOS);
    expect(AppTheme.dark.platform, TargetPlatform.iOS);
  });

  test('has the colors of the design handoff (docs/design/README.md)', () {
    expect(_hex(_roles(AppTheme.light.colorScheme)), {
      'primary': '#006879',
      'onPrimary': '#FFFFFF',
      'primaryContainer': '#A9EDFF',
      'onPrimaryContainer': '#004E5B',
      'secondaryContainer': '#CEE7EE',
      'onSecondaryContainer': '#334A50',
      'surface': '#F5FAFC',
      'surfaceContainerLowest': '#FFFFFF',
      'surfaceContainerLow': '#EFF4F6',
      'surfaceContainer': '#E9EFF1',
      'surfaceContainerHigh': '#E4E9EB',
      'surfaceContainerHighest': '#DEE3E5',
      'onSurface': '#171D1E',
      'onSurfaceVariant': '#3F484B',
      'outline': '#6F797B',
      'outlineVariant': '#BFC8CB',
      'error': '#BA1A1A',
      'errorContainer': '#FFDAD6',
      'onErrorContainer': '#93000A',
    });
    expect(_hex(_roles(AppTheme.dark.colorScheme)), {
      'primary': '#84D2E5',
      'onPrimary': '#003640',
      'primaryContainer': '#004E5B',
      'onPrimaryContainer': '#A9EDFF',
      'secondaryContainer': '#334A50',
      'onSecondaryContainer': '#CEE7EE',
      'surface': '#0F1416',
      'surfaceContainerLowest': '#090F11',
      'surfaceContainerLow': '#171D1E',
      'surfaceContainer': '#1B2122',
      'surfaceContainerHigh': '#252B2D',
      'surfaceContainerHighest': '#303637',
      'onSurface': '#DEE3E5',
      'onSurfaceVariant': '#BFC8CB',
      'outline': '#899295',
      'outlineVariant': '#3F484B',
      'error': '#FFB4AB',
      'errorContainer': '#93000A',
      'onErrorContainer': '#FFDAD6',
    });
    expect(_hex(_payment(AppTheme.light.extension<PaymentColors>()!)), {
      'cashContainer': '#B8F1B9',
      'onCashContainer': '#1D5128',
      'cardContainer': '#D5E3FF',
      'onCardContainer': '#234776',
    });
    expect(_hex(_payment(AppTheme.dark.extension<PaymentColors>()!)), {
      'cashContainer': '#1D5128',
      'onCashContainer': '#B8F1B9',
      'cardContainer': '#234776',
      'onCardContainer': '#D5E3FF',
    });
  });

  test('puts cards on the screen background in both themes', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(
      (light.scaffoldBackgroundColor, light.cardTheme.color),
      (
        light.colorScheme.surfaceContainer,
        light.colorScheme.surfaceContainerLowest,
      ),
    );
    expect(
      (dark.scaffoldBackgroundColor, dark.cardTheme.color),
      (dark.colorScheme.surface, dark.colorScheme.surfaceContainerHigh),
    );
    expect(light.cardTheme.elevation, 0);
  });

  test('has no ripple on iOS and a sparkle on Android', () {
    expect(AppTheme.light.splashFactory, InkSparkle.splashFactory);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(AppTheme.light.splashFactory, NoSplash.splashFactory);
    expect(AppTheme.dark.splashFactory, NoSplash.splashFactory);
  });

  testWidgets('takes Cupertino icons on iOS and Material icons elsewhere, '
      'except cash and card', (tester) async {
    late AppIcons icons;
    Future<void> pumpOn(TargetPlatform platform) => tester.pumpWidget(
      Theme(
        data: ThemeData(platform: platform),
        child: Builder(
          builder: (context) {
            icons = AppIcons.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await pumpOn(TargetPlatform.iOS);
    expect(
      (icons.previousDay, icons.close, icons.offline, icons.dayArrowSize),
      (
        CupertinoIcons.chevron_left,
        CupertinoIcons.xmark,
        CupertinoIcons.wifi_slash,
        24,
      ),
    );

    await pumpOn(TargetPlatform.android);
    expect(
      (icons.previousDay, icons.close, icons.offline, icons.dayArrowSize),
      (Icons.chevron_left, Icons.close, Icons.cloud_off_outlined, 28),
    );

    expect(
      (AppIcons.cash, AppIcons.card),
      (Icons.payments_rounded, Icons.credit_card_rounded),
    );
  });
}

import 'package:driver_shifts/src/core/theme/payment_colors.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF00AFCA);
  static const int _errorMaxLines = 4;
  static const double _scrimOpacity = 0.32;
  static const double _pressedOverlayOpacity = 0.08;

  static ThemeData get light => _themeFor(Brightness.light);
  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;
    final background = isLight ? colors.surfaceContainer : colors.surface;
    final isCupertino = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
    final pressed = isCupertino
        ? ButtonStyle(
            overlayColor: WidgetStatePropertyAll(
              colors.onSurface.withValues(alpha: _pressedOverlayOpacity),
            ),
          )
        : null;
    final base = ThemeData(colorScheme: colors);
    final strongTitle = base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    const largeShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Radii.large)),
    );
    final sheetBackground = isLight
        ? colors.surfaceContainer
        : colors.surfaceContainerLow;
    return base.copyWith(
      scaffoldBackgroundColor: background,
      splashFactory: isCupertino ? NoSplash.splashFactory : null,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: largeShape,
        color: isLight
            ? colors.surfaceContainerLowest
            : colors.surfaceContainerHigh,
      ),
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        toolbarHeight: Sizes.toolbar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        titleTextStyle: strongTitle,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Sizes.mainButton),
          shape: largeShape,
          textStyle: strongTitle,
          iconSize: Sizes.icon,
          backgroundColor: isLight ? null : colors.primaryContainer,
          foregroundColor: isLight ? null : colors.onPrimaryContainer,
        ).merge(pressed),
      ),
      textButtonTheme: TextButtonThemeData(style: pressed),
      iconButtonTheme: IconButtonThemeData(style: pressed),
      segmentedButtonTheme: SegmentedButtonThemeData(style: pressed),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetBackground,
        modalBackgroundColor: sheetBackground,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim.withValues(alpha: _scrimOpacity),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        border: OutlineInputBorder(),
        errorMaxLines: _errorMaxLines,
      ),
      extensions: [PaymentColors.of(brightness)],
    );
  }
}

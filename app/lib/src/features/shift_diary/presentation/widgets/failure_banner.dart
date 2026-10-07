import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

IconData failureIcon(Failure failure, AppIcons icons) => switch (failure) {
  ConnectionFailure() ||
  TimeoutFailure() ||
  BadResponseFailure() => icons.offline,
  ValidationFailure() ||
  ConflictFailure() ||
  UnexpectedFailure() => icons.error,
};

class FailureBanner extends StatelessWidget {
  const FailureBanner({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onRetry = this.onRetry;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          Spacing.md,
          Spacing.sml,
          onRetry == null ? Spacing.md : Spacing.sm,
          onRetry == null ? Spacing.sml : Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: onRetry == null ? 0 : Spacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    failureIcon(failure, AppIcons.of(context)),
                    size: Sizes.icon,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: Spacing.sml),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        failure.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: AppTheme.withPlatformPress(
                  context,
                  TextButton.styleFrom(
                    foregroundColor: colors.onErrorContainer,
                    textStyle: AppTextStyles.strong(theme.textTheme.labelLarge),
                    minimumSize: const Size.square(Sizes.touchTarget),
                  ),
                ),
                child: const Text(ShiftDiaryStrings.retry),
              ),
          ],
        ),
      ),
    );
  }
}

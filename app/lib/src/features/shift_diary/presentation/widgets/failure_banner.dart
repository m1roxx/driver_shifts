import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

class FailureBanner extends StatelessWidget {
  const FailureBanner({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onRetry = this.onRetry;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.errorContainer,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          Spacing.md,
          Spacing.md,
          onRetry == null ? Spacing.md : Spacing.sm,
          onRetry == null ? Spacing.md : Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(switch (failure) {
                  ConnectionFailure() ||
                  TimeoutFailure() ||
                  BadResponseFailure() => Icons.cloud_off_outlined,
                  ValidationFailure() ||
                  ConflictFailure() ||
                  UnexpectedFailure() => Icons.error_outline,
                }, color: colors.onErrorContainer),
                const SizedBox(width: Spacing.md),
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
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onErrorContainer,
                ),
                child: const Text(ShiftDiaryStrings.retry),
              ),
          ],
        ),
      ),
    );
  }
}

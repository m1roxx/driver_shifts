import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

class RefreshFailureBanner extends StatelessWidget {
  const RefreshFailureBanner({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.md,
          Spacing.md,
          Spacing.sm,
          Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
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

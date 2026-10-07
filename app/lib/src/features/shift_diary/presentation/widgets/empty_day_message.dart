import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

class EmptyDayMessage extends StatelessWidget {
  const EmptyDayMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: theme.textTheme.displaySmall?.fontSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            ShiftDiaryStrings.noTrips,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

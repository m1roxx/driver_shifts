import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

class NextDayBadge extends StatelessWidget {
  const NextDayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.small)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.badgePadding,
            vertical: Spacing.xxs,
          ),
          child: Text(
            ShiftDiaryStrings.nextDayBadge,
            style: AppTextStyles.strong(theme.textTheme.labelMedium)
                ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}

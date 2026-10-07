import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/state_message.dart';
import 'package:flutter/material.dart';

class EmptyDayMessage extends StatelessWidget {
  const EmptyDayMessage({super.key, this.title = ShiftDiaryStrings.noTrips});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StateMessage(
      icon: AppIcons.of(context).emptyDay,
      iconBackground: theme.cardTheme.color,
      iconColor: theme.colorScheme.onSurfaceVariant,
      title: title,
    );
  }
}

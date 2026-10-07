import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

enum DiaryMode {
  day(null, ShiftDiaryStrings.day),
  week(PeriodKind.week, ShiftDiaryStrings.week),
  month(PeriodKind.month, ShiftDiaryStrings.month);

  const DiaryMode(this.periodKind, this.label);

  final PeriodKind? periodKind;
  final String label;
}

class DiaryModeSegments extends StatelessWidget {
  const DiaryModeSegments({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final DiaryMode mode;
  final ValueChanged<DiaryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colors.onPrimaryContainer
          : colors.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, 0),
      child: Semantics(
        container: true,
        label: ShiftDiaryStrings.viewMode,
        child: SegmentedButton<DiaryMode>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          style:
              SegmentedButton.styleFrom(
                minimumSize: const Size.square(Sizes.touchTarget),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                textStyle: AppTextStyles.strong(theme.textTheme.labelLarge),
              ).copyWith(
                side: WidgetStatePropertyAll(BorderSide(color: colors.outline)),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? colors.primaryContainer
                      : null,
                ),
                foregroundColor: foreground,
              ),
          segments: [
            for (final mode in DiaryMode.values)
              ButtonSegment(
                value: mode,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(mode.label, maxLines: 1, softWrap: false),
                ),
              ),
          ],
          selected: {mode},
          onSelectionChanged: (selected) => onChanged(selected.single),
        ),
      ),
    );
  }
}

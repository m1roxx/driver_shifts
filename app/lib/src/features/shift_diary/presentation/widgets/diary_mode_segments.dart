import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/sliding_segmented_control.dart';
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
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.viewMode,
      child: SlidingSegmentedControl<DiaryMode>(
        values: DiaryMode.values,
        labelOf: (mode) => mode.label,
        selected: mode,
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_report_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder dayList = find
    .descendant(
      of: find.byType(DayReportView),
      matching: find.byType(Scrollable),
    )
    .first;

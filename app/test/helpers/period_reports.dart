import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';

import 'day_reports.dart';

final DateTime sep28 = DateTime.utc(2026, 9, 28);
final DateTime oct4 = DateTime.utc(2026, 10, 4);

const DaySummary emptySummary = DaySummary(
  tripsCount: 0,
  revenue: 0,
  commission: 0,
  net: 0,
  byPayment: PaymentBreakdown(cash: 0, card: 0),
);

const DaySummary sep30Summary = DaySummary(
  tripsCount: 3,
  revenue: 7100,
  commission: 1065,
  net: 6035,
  byPayment: PaymentBreakdown(cash: 3200, card: 3900),
);

const DaySummary oct3Summary = DaySummary(
  tripsCount: 1,
  revenue: 1500,
  commission: 225,
  net: 1275,
  byPayment: PaymentBreakdown(cash: 1500, card: 0),
);

const String apiWeekExample = '''
{
  "start": "2026-09-28",
  "end": "2026-10-04",
  "timezone": "Asia/Almaty",
  "summary": {"trips_count": 9, "revenue": 21040, "commission": 3156, "net": 17884,
              "by_payment": {"cash": 8900, "card": 12140}},
  "days": [
    {"date": "2026-09-28", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}},
    {"date": "2026-09-29", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}},
    {"date": "2026-09-30", "summary": {"trips_count": 3, "revenue": 7100, "commission": 1065,
      "net": 6035, "by_payment": {"cash": 3200, "card": 3900}}},
    {"date": "2026-10-01", "summary": {"trips_count": 2, "revenue": 3900, "commission": 585,
      "net": 3315, "by_payment": {"cash": 1500, "card": 2400}}},
    {"date": "2026-10-02", "summary": {"trips_count": 3, "revenue": 8540, "commission": 1281,
      "net": 7259, "by_payment": {"cash": 2700, "card": 5840}}},
    {"date": "2026-10-03", "summary": {"trips_count": 1, "revenue": 1500, "commission": 225,
      "net": 1275, "by_payment": {"cash": 1500, "card": 0}}},
    {"date": "2026-10-04", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}}
  ]
}
''';

final PeriodReport seedWeekReport = PeriodReport(
  start: sep28,
  end: oct4,
  summary: const DaySummary(
    tripsCount: 9,
    revenue: 21040,
    commission: 3156,
    net: 17884,
    byPayment: PaymentBreakdown(cash: 8900, card: 12140),
  ),
  days: [
    DayTotal(date: sep28, summary: emptySummary),
    DayTotal(date: DateTime.utc(2026, 9, 29), summary: emptySummary),
    DayTotal(date: sep30, summary: sep30Summary),
    DayTotal(date: oct1, summary: taskExampleReport.summary),
    DayTotal(date: oct2, summary: oct2Report.summary),
    DayTotal(date: DateTime.utc(2026, 10, 3), summary: oct3Summary),
    DayTotal(date: oct4, summary: emptySummary),
  ],
);

PeriodReport periodReportOf(
  DateTime start,
  DateTime end,
  Map<DateTime, DayReport> reports,
) {
  final days = [
    for (
      var day = start;
      !day.isAfter(end);
      day = DateTime.utc(day.year, day.month, day.day + 1)
    )
      DayTotal(date: day, summary: reports[day]?.summary ?? emptySummary),
  ];
  int total(int Function(DaySummary summary) field) =>
      days.fold(0, (sum, day) => sum + field(day.summary));
  return PeriodReport(
    start: start,
    end: end,
    summary: DaySummary(
      tripsCount: total((summary) => summary.tripsCount),
      revenue: total((summary) => summary.revenue),
      commission: total((summary) => summary.commission),
      net: total((summary) => summary.net),
      byPayment: PaymentBreakdown(
        cash: total((summary) => summary.byPayment.cash),
        card: total((summary) => summary.byPayment.card),
      ),
    ),
    days: days,
  );
}

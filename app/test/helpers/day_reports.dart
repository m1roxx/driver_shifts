import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';

final DateTime sep30 = DateTime.utc(2026, 9, 30);
final DateTime oct1 = DateTime.utc(2026, 10);
final DateTime oct2 = DateTime.utc(2026, 10, 2);

const String apiDayExample = '''
{
  "date": "2026-10-01",
  "timezone": "Asia/Almaty",
  "summary": {
    "trips_count": 2,
    "revenue": 3900,
    "commission": 585,
    "net": 3315,
    "by_payment": {"cash": 1500, "card": 2400}
  },
  "trips": [
    {"id": "t1", "start": "2026-10-01T08:10:00+05:00", "end": "2026-10-01T08:32:00+05:00",
     "amount": 2400, "payment": "card", "commission": 360},
    {"id": "t2", "start": "2026-10-01T09:05:00+05:00", "end": "2026-10-01T09:20:00+05:00",
     "amount": 1500, "payment": "cash", "commission": 225}
  ]
}
''';

final DayReport taskExampleReport = DayReport(
  date: oct1,
  summary: const DaySummary(
    tripsCount: 2,
    revenue: 3900,
    commission: 585,
    net: 3315,
    byPayment: PaymentBreakdown(cash: 1500, card: 2400),
  ),
  trips: [
    Trip(
      id: 't1',
      start: DateTime.utc(2026, 10, 1, 3, 10),
      end: DateTime.utc(2026, 10, 1, 3, 32),
      amount: 2400,
      payment: PaymentMethod.card,
      commission: 360,
    ),
    Trip(
      id: 't2',
      start: DateTime.utc(2026, 10, 1, 4, 5),
      end: DateTime.utc(2026, 10, 1, 4, 20),
      amount: 1500,
      payment: PaymentMethod.cash,
      commission: 225,
    ),
  ],
);

final DayReport oct2Report = DayReport(
  date: oct2,
  summary: const DaySummary(
    tripsCount: 3,
    revenue: 8540,
    commission: 1281,
    net: 7259,
    byPayment: PaymentBreakdown(cash: 2700, card: 5840),
  ),
  trips: [
    Trip(
      id: 't6',
      start: DateTime.utc(2026, 10, 1, 19, 30),
      end: DateTime.utc(2026, 10, 1, 19, 55),
      amount: 2700,
      payment: PaymentMethod.cash,
      commission: 405,
    ),
    Trip(
      id: 't7',
      start: DateTime.utc(2026, 10, 2, 7, 10),
      end: DateTime.utc(2026, 10, 2, 7, 35),
      amount: 1240,
      payment: PaymentMethod.card,
      commission: 186,
    ),
    Trip(
      id: 't8',
      start: DateTime.utc(2026, 10, 2, 18, 50),
      end: DateTime.utc(2026, 10, 2, 19, 20),
      amount: 4600,
      payment: PaymentMethod.card,
      commission: 690,
    ),
  ],
);

const String eveningTripId = '0199b4a2-3c1d-7e8f-9a0b-1c2d3e4f5a6b';

const String apiEveningTripExample = '''
{"id": "0199b4a2-3c1d-7e8f-9a0b-1c2d3e4f5a6b",
 "start": "2026-10-01T18:40:00+05:00", "end": "2026-10-01T19:05:00+05:00",
 "amount": 1000, "payment": "cash", "commission": 150}
''';

final Trip eveningTrip = Trip(
  id: eveningTripId,
  start: DateTime.utc(2026, 10, 1, 13, 40),
  end: DateTime.utc(2026, 10, 1, 14, 5),
  amount: 1000,
  payment: PaymentMethod.cash,
  commission: 150,
);

final DayReport oct1WithEveningTrip = DayReport(
  date: oct1,
  summary: const DaySummary(
    tripsCount: 3,
    revenue: 4900,
    commission: 735,
    net: 4165,
    byPayment: PaymentBreakdown(cash: 2500, card: 2400),
  ),
  trips: [...taskExampleReport.trips, eveningTrip],
);

DayReport emptyReport(DateTime date) => DayReport(
  date: date,
  summary: const DaySummary(
    tripsCount: 0,
    revenue: 0,
    commission: 0,
    net: 0,
    byPayment: PaymentBreakdown(cash: 0, card: 0),
  ),
  trips: const [],
);

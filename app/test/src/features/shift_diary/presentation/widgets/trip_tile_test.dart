import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/trip_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _trip(String start, String end) => Trip(
  id: start,
  start: DateTime.parse(start),
  end: DateTime.parse(end),
  amount: 1000,
  payment: PaymentMethod.card,
  commission: 150,
);

Future<void> _pumpTiles(WidgetTester tester, List<Trip> trips) =>
    tester.pumpWidget(
      RepositoryProvider.value(
        value: DriverClock(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [for (final trip in trips) TripTile(trip: trip)],
            ),
          ),
        ),
      ),
    );

bool _hasBadge(WidgetTester tester, String times) => find
    .descendant(
      of: find.ancestor(of: find.text(times), matching: find.byType(TripTile)),
      matching: find.text('+1 день'),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('«+1 день» follows the Almaty calendar, whatever the phone '
      'time zone and UTC say', (tester) async {
    await _pumpTiles(tester, [
      _trip('2026-10-02T23:50:00+05:00', '2026-10-03T00:20:00+05:00'),
      _trip('2026-10-02T00:30:00+05:00', '2026-10-02T00:55:00+05:00'),
      _trip('2026-10-02T04:50:00+05:00', '2026-10-02T05:10:00+05:00'),
      _trip('2026-10-02T08:50:00+05:00', '2026-10-02T09:10:00+05:00'),
      _trip('2026-10-02T14:50:00+05:00', '2026-10-02T15:10:00+05:00'),
    ]);

    expect(
      {
        for (final times in [
          '23:50\u00A0– 00:20',
          '00:30\u00A0– 00:55',
          '04:50\u00A0– 05:10',
          '08:50\u00A0– 09:10',
          '14:50\u00A0– 15:10',
        ])
          times: _hasBadge(tester, times),
      },
      {
        '23:50\u00A0– 00:20': true,
        '00:30\u00A0– 00:55': false,
        '04:50\u00A0– 05:10': false,
        '08:50\u00A0– 09:10': false,
        '14:50\u00A0– 15:10': false,
      },
    );
    expect(find.bySemanticsLabel(RegExp('следующего дня')), findsOneWidget);
  });
}

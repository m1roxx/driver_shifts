import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/add_trip_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';

final RegExp _uuidV7 = RegExp(
  '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\$',
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(AddTripSheet), matching: finder);

Finder _field(String label) => find
    .ancestor(
      of: _inSheet(find.text(label)),
      matching: find.byType(InputDecorator),
    )
    .first;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) =>
    _tap(tester, find.byTooltip('Добавить поездку'));

Future<void> _pickTime(
  WidgetTester tester,
  String field,
  int hour,
  int minute,
) async {
  await _tap(
    tester,
    find.descendant(of: _field(field), matching: find.byIcon(Icons.schedule)),
  );
  await tester.tap(find.byTooltip('Перейти в режим ввода текста'));
  await tester.pumpAndSettle();
  final inputs = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(inputs.at(0), '$hour');
  await tester.enterText(inputs.at(1), '$minute');
  await _tap(tester, find.text('ОК'));
}

Future<void> _enterMoney(WidgetTester tester, String label, String text) async {
  final field = _inSheet(find.widgetWithText(TextField, label));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _fillEveningTrip(WidgetTester tester) async {
  await _pickTime(tester, 'Начало', 18, 40);
  await _pickTime(tester, 'Окончание', 19, 5);
  await _enterMoney(tester, 'Сумма', '1000');
  await _enterMoney(tester, 'Комиссия', '150');
  await _tap(tester, _inSheet(find.text('Наличные')));
}

Future<void> _save(WidgetTester tester) =>
    _tap(tester, _inSheet(find.text('Сохранить')));

List<Object?> _recordHaptics(WidgetTester tester) {
  final haptics = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return haptics;
}

void main() {
  testWidgets('a trip added on the open day shows up in the server summary '
      'of that day', (tester) async {
    final reports = <DateTime, DayReport>{oct1: taskExampleReport};
    final repository = FakeTripsRepository.withReports(
      reports,
      onAddTrip: (trip) async {
        reports[oct1] = oct1WithEveningTrip.copyWith(
          trips: [...taskExampleReport.trips, trip],
        );
        return Result.success(trip);
      },
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('На руки 3\u00A0315 тенге'), findsOneWidget);

    await _openForm(tester);
    expect(_inSheet(find.text('Новая поездка')), findsOneWidget);
    expect(_inSheet(find.text('1 октября')), findsNWidgets(2));
    await _fillEveningTrip(tester);
    expect(_inSheet(find.text('18:40')), findsOneWidget);
    expect(_inSheet(find.text('19:05')), findsOneWidget);
    expect(_inSheet(find.text('1\u00A0000')), findsOneWidget);
    final haptics = _recordHaptics(tester);
    await _save(tester);

    expect(find.byType(AddTripSheet), findsNothing);
    expect(find.bySemanticsLabel('На руки 4\u00A0165 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Поездки 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Выручка 4\u00A0900 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Комиссия 735 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Наличные 2\u00A0500 тенге'), findsOneWidget);
    expect(find.text('18:40\u00A0– 19:05'), findsOneWidget);
    final trip = repository.addedTrips.single;
    expect(trip.id, matches(_uuidV7));
    expect(trip, eveningTrip.copyWith(id: trip.id));
    expect(repository.requestedDays, [oct1, oct1]);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a retry after a lost connection resends the trip with the '
      'same id (D7)', (tester) async {
    var attempts = 0;
    final repository = FakeTripsRepository.withReports(
      {oct1: taskExampleReport},
      onAddTrip: (trip) async => ++attempts == 1
          ? const Result.error(Failure.connection())
          : Result.success(trip),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);

    await _save(tester);

    expect(
      _inSheet(find.text(const Failure.connection().message)),
      findsOneWidget,
    );
    expect(
      inLiveRegion(tester, find.text(const Failure.connection().message)),
      isTrue,
    );
    expect(_inSheet(find.text('Сохранить')), findsNothing);

    await _tap(tester, _inSheet(find.text('Повторить')));

    expect(find.byType(AddTripSheet), findsNothing);
    final ids = repository.addedTrips.map((trip) => trip.id).toList();
    expect(ids, hasLength(2));
    expect(ids.toSet(), hasLength(1));
  });

  testWidgets('a trip after midnight in Almaty opens its own day, not the '
      'UTC one', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);

    await _tap(
      tester,
      find.descendant(of: _field('Начало'), matching: find.text('1 октября')),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('2'),
      ),
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(_inSheet(find.text('2 октября')), findsNWidgets(2));
    await _pickTime(tester, 'Начало', 0, 30);
    await _pickTime(tester, 'Окончание', 0, 55);
    await _enterMoney(tester, 'Сумма', '2700');
    await _enterMoney(tester, 'Комиссия', '405');
    await _tap(tester, _inSheet(find.text('Наличные')));
    await _save(tester);

    expect(
      repository.addedTrips.single.start,
      DateTime.utc(2026, 10, 1, 19, 30),
    );
    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct2]);
  });

  testWidgets('shows the form errors under their fields and sends nothing', (
    tester,
  ) async {
    final repository = FakeTripsRepository.withReports({});
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Добавить поездку'));

    await _save(tester);

    const fieldErrors = {
      'Начало': ('Начало', 'Выберите время начала'),
      'Окончание': ('Окончание', 'Выберите время окончания'),
      'Сумма': ('Сумма в тенге', 'Введите сумму'),
      'Комиссия': ('Комиссия в тенге', 'Введите комиссию, если её нет — 0'),
      'Способ оплаты': ('Способ оплаты', 'Выберите наличные или карту'),
    };
    for (final MapEntry(key: field, value: (spoken, error))
        in fieldErrors.entries) {
      expect(_inSheet(find.text(error)), findsOneWidget, reason: error);
      expect(
        tester.getSemantics(_field(field)),
        isSemantics(label: spoken, hint: error),
        reason: 'VoiceOver reads the error with the field',
      );
    }
    expect(_inSheet(find.text('Проверьте данные поездки.')), findsOneWidget);
    expect(
      inLiveRegion(tester, _inSheet(find.text('Проверьте данные поездки.'))),
      isTrue,
    );
    expect(repository.addedTrips, isEmpty);

    await _enterMoney(tester, 'Сумма', '1000');
    expect(_inSheet(find.text('Введите сумму')), findsNothing);
  });

  testWidgets('TalkBack hears the field errors as they appear: Android has '
      'no announcements, so they are live regions', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);

    await _save(tester);

    for (final error in ['Выберите время начала', 'Введите сумму']) {
      expect(inLiveRegion(tester, _inSheet(find.text(error))), isTrue);
    }
  });

  testWidgets('puts 422 errors under their fields by type, never the '
      'English msg', (tester) async {
    final repository = FakeTripsRepository.withReports(
      {oct1: taskExampleReport},
      onAddTrip: (_) async => const Result.error(
        Failure.validation(
          fieldErrors: {
            'end': 'end_not_after_start',
            'commission': 'commission_above_amount',
            'amount': 'a_type_added_later',
          },
        ),
      ),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);

    await _save(tester);

    expect(
      _inSheet(find.text('Окончание должно быть позже начала')),
      findsOneWidget,
    );
    expect(
      _inSheet(find.text('Комиссия не может быть больше суммы')),
      findsOneWidget,
    );
    expect(_inSheet(find.text('Проверьте сумму')), findsOneWidget);
    expect(_inSheet(find.text('Проверьте данные поездки.')), findsOneWidget);
    expect(_inSheet(find.text('Сохранить')), findsOneWidget);
    expect(find.byType(AddTripSheet), findsOneWidget);
  });

  testWidgets('shows the 409 message and offers no retry', (tester) async {
    const message = 'Поездка с id t1 уже сохранена с другими данными';
    final repository = FakeTripsRepository.withReports(
      {oct1: taskExampleReport},
      onAddTrip: (_) async =>
          const Result.error(Failure.conflict(serverMessage: message)),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);

    await _save(tester);

    expect(_inSheet(find.text(message)), findsOneWidget);
    expect(inLiveRegion(tester, _inSheet(find.text(message))), isTrue);
    expect(_inSheet(find.text('Сохранить')), findsOneWidget);
    expect(_inSheet(find.text('Повторить')), findsNothing);
    expect(repository.requestedDays, [oct1]);
  });

  testWidgets('keeps the form open and sends once while the trip is on its '
      'way', (tester) async {
    final response = Completer<Result<Trip>>();
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    }, onAddTrip: (_) => response.future);
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);
    final save = _inSheet(find.byType(FilledButton));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();

    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tapAt(const Offset(400, 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AddTripSheet), findsOneWidget);
    expect(find.bySemanticsLabel('Поездка сохраняется'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            _inSheet(find.widgetWithIcon(IconButton, Icons.close)),
          )
          .onPressed,
      isNull,
    );
    expect(repository.addedTrips, hasLength(1));

    response.complete(Result.success(repository.addedTrips.single));
    await tester.pumpAndSettle();

    expect(find.byType(AddTripSheet), findsNothing);
    expect(repository.addedTrips, hasLength(1));
  });

  testWidgets('closes without sending anything', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _enterMoney(tester, 'Сумма', '1000');

    await _tap(tester, find.byTooltip('Закрыть'));

    expect(find.byType(AddTripSheet), findsNothing);
    expect(repository.addedTrips, isEmpty);
    expect(repository.requestedDays, [oct1]);
  });

  testWidgets('picks the time in a 24-hour Cupertino sheet on iOS', (
    tester,
  ) async {
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);

    await _tap(
      tester,
      find.descendant(
        of: _field('Начало'),
        matching: find.byIcon(Icons.schedule),
      ),
    );
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.mode, CupertinoDatePickerMode.time);
    expect(picker.use24hFormat, isTrue);
    expect(
      (picker.initialDateTime.hour, picker.initialDateTime.minute),
      (11, 0),
    );
    picker.onDateTimeChanged(DateTime(2000, 1, 1, 23, 50));
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    expect(_inSheet(find.text('23:50')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('the end time picker starts from the start time', (tester) async {
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _pickTime(tester, 'Начало', 18, 40);

    await _tap(
      tester,
      find.descendant(
        of: _field('Окончание'),
        matching: find.byIcon(Icons.schedule),
      ),
    );

    final dialog = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(dialog.initialTime, const TimeOfDay(hour: 18, minute: 40));
  });

  for (final brightness in Brightness.values) {
    group('at 200% text in the ${brightness.name} theme on a small phone', () {
      testWidgets('the form with every error', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({
            oct1: taskExampleReport,
          }, onAddTrip: (_) async => const Result.error(Failure.timeout())),
        );
        await tester.pumpAndSettle();
        await _openForm(tester);

        final theme = Theme.of(tester.element(find.byType(AddTripSheet)));
        expect(theme.colorScheme.brightness, brightness);
        await _save(tester);
        await tester.ensureVisible(_inSheet(find.text('Новая поездка')));
        await tester.pumpAndSettle();
        expect(_inSheet(find.text('Выберите время начала')), findsOneWidget);

        await _fillEveningTrip(tester);
        await _save(tester);
        expect(
          _inSheet(find.text(const Failure.timeout().message)),
          findsOneWidget,
        );
        await tester.ensureVisible(_inSheet(find.text('Повторить')));
      });

      testWidgets(
        'the time picker',
        (tester) async {
          useSmallPhone(tester, brightness: brightness, textScale: 2);
          await pumpApp(tester, FakeTripsRepository.withReports({}));
          await tester.pumpAndSettle();
          await _openForm(tester);

          await _tap(
            tester,
            find.descendant(
              of: _field('Начало'),
              matching: find.byIcon(Icons.schedule),
            ),
          );

          if (defaultTargetPlatform == TargetPlatform.iOS) {
            expect(find.byType(CupertinoDatePicker), findsOneWidget);
          } else {
            final dialog = tester.element(find.byType(TimePickerDialog));
            expect(MediaQuery.textScalerOf(dialog).scale(10), 13);
          }
        },
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );
    });
  }
}

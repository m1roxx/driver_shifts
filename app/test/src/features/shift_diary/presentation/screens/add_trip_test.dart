import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/add_trip_sheet.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_list.dart';
import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';

final RegExp _uuidV7 = RegExp(
  '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\$',
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(AddTripSheet), matching: finder);

Finder _field(String label) => _inSheet(
  find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
);

Finder _picker(String field, String part) =>
    _inSheet(find.bySemanticsLabel(RegExp('^$field, $part ')));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(FilledButton, 'Добавить поездку'));

Future<void> _pickTime(
  WidgetTester tester,
  String field,
  int hour,
  int minute,
) async {
  await _tap(tester, _picker(field, 'время'));
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

Finder _moneyField(String label) => find.descendant(
  of: _inSheet(find.widgetWithText(MoneyField, label)),
  matching: find.byType(TextField),
);

Future<void> _enterMoney(WidgetTester tester, String label, String text) async {
  final field = _moneyField(label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

({bool focused, bool keyboard}) _typingIn(WidgetTester tester, String label) =>
    (
      focused: tester
          .widget<EditableText>(
            find.descendant(
              of: _moneyField(label),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      keyboard: tester.testTextInput.isVisible,
    );

const _numberPadOnSmallPhone = 216.0;

const _typing = (focused: true, keyboard: true);
const _notTyping = (focused: false, keyboard: false);

Future<void> _fillEveningTrip(WidgetTester tester) async {
  await _pickTime(tester, 'Начало', 18, 40);
  await _pickTime(tester, 'Окончание', 19, 5);
  await _enterMoney(tester, 'Сумма', '1000');
  await _enterMoney(tester, 'Комиссия', '150');
  await _tap(tester, _inSheet(find.text('Наличные')));
}

Axis _paymentDirection(WidgetTester tester) => tester
    .widget<SegmentedButton<PaymentMethod>>(
      find.byType(SegmentedButton<PaymentMethod>),
    )
    .direction;

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
    expect(
      find.bySemanticsLabel('На руки 3\u00A0315 тенге, 2\u00A0поездки'),
      findsOneWidget,
    );

    await _openForm(tester);
    expect(_inSheet(find.text('Новая поездка')), findsOneWidget);
    expect(_paymentDirection(tester), Axis.horizontal);
    expect(_inSheet(find.text('1 октября')), findsNWidgets(2));
    await _fillEveningTrip(tester);
    expect(_inSheet(find.text('18:40')), findsOneWidget);
    expect(_inSheet(find.text('19:05')), findsOneWidget);
    expect(_inSheet(find.text('1\u00A0000')), findsOneWidget);
    final haptics = _recordHaptics(tester);
    await _save(tester);

    expect(find.byType(AddTripSheet), findsNothing);
    expect(
      find.bySemanticsLabel('На руки 4\u00A0165 тенге, 3\u00A0поездки'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Выручка 4\u00A0900 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Комиссия 735 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Наличные 2\u00A0500 тенге'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('18:40\u00A0– 19:05'),
      100,
      scrollable: dayList,
    );
    final trip = repository.addedTrips.single;
    expect(trip.id, matches(_uuidV7));
    expect(trip, eveningTrip.copyWith(id: trip.id));
    expect(repository.requestedDays, [oct1, oct1]);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a saved trip is announced and its row fades from the '
      'highlight to the card in 1.2 s', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final announcements = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async => announcements.add(message),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    final reports = <DateTime, DayReport>{oct1: taskExampleReport};
    await pumpApp(
      tester,
      FakeTripsRepository.withReports(
        reports,
        onAddTrip: (trip) async {
          reports[oct1] = oct1WithEveningTrip.copyWith(
            trips: [...taskExampleReport.trips, trip],
          );
          return Result.success(trip);
        },
      ),
    );
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);
    final save = _inSheet(find.text('Сохранить'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();

    await tester.tap(save);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    Color? background(String times) =>
        (tester
                    .widgetList<DecoratedBox>(
                      find.ancestor(
                        of: find.text(times),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .first
                    .decoration
                as BoxDecoration)
            .color;
    final colors = Theme.of(tester.element(find.text('18:40\u00A0– 19:05')))
        .colorScheme;
    expect(
      background('18:40\u00A0– 19:05'),
      isSameColorAs(colors.secondaryContainer, threshold: 0.2),
    );
    expect(background('08:10\u00A0– 08:32'), isNull);
    expect(
      announcements,
      contains(
        containsPair('data', containsPair('message', 'Поездка добавлена')),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    expect(background('18:40\u00A0– 19:05'), isNull);
  });

  testWidgets('the new trip is highlighted once: scrolled away and back, '
      'its row stays the card colour', (tester) async {
    useSmallPhone(tester);
    final reports = <DateTime, DayReport>{oct1: longReport};
    await pumpApp(
      tester,
      FakeTripsRepository.withReports(
        reports,
        onAddTrip: (trip) async {
          reports[oct1] = longReport.copyWith(
            trips: [trip, ...longReport.trips],
          );
          return Result.success(trip);
        },
      ),
    );
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);
    await _save(tester);
    await tester.pump(const Duration(seconds: 2));

    final row = find.text('18:40\u00A0– 19:05');
    Color? background() =>
        (tester
                    .widgetList<DecoratedBox>(
                      find.ancestor(
                        of: row,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .first
                    .decoration
                as BoxDecoration)
            .color;
    expect(find.byType(AddTripSheet), findsNothing);
    final list = find.byType(CustomScrollView);
    await tester.drag(list, const Offset(0, 5000));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(row, list, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(background(), isNull);

    await tester.drag(list, const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(row, findsNothing, reason: 'the row left the list');
    await tester.drag(list, const Offset(0, 5000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.dragUntilVisible(row, list, const Offset(0, -100));
    await tester.pump();

    expect(background(), isNull);
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

    await _tap(tester, _picker('Начало', 'день'));
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
      final node = field == 'Сумма' || field == 'Комиссия'
          ? find.descendant(
              of: _moneyField(field),
              matching: find.byType(EditableText),
            )
          : _field(field);
      expect(
        tester.getSemantics(node),
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

  testWidgets('after 409 explains the trip is already stored, offers only '
      '«Закрыть» and shows the day of the trip again', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    }, onAddTrip: (_) async => const Result.error(Failure.conflict()));
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);

    await _save(tester);

    const message =
        'Эта поездка уже сохранена — с данными первой отправки. '
        'Проверьте её в списке.';
    expect(_inSheet(find.text(message)), findsOneWidget);
    expect(inLiveRegion(tester, _inSheet(find.text(message))), isTrue);
    expect(_inSheet(find.text('Сохранить')), findsNothing);
    expect(_inSheet(find.text('Повторить')), findsNothing);
    expect(
      tester.widget<TextField>(_inSheet(find.byType(TextField)).first).enabled,
      isFalse,
    );
    final chosen = tester.widget<Material>(
      find
          .ancestor(
            of: _inSheet(find.text('Наличные')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      chosen.color,
      Theme.of(tester.element(find.byType(AddTripSheet)))
          .colorScheme
          .secondaryContainer,
      reason: 'the locked form still shows which payment was sent',
    );
    expect(repository.requestedDays, [oct1]);

    await _tap(tester, _inSheet(find.widgetWithText(FilledButton, 'Закрыть')));

    expect(find.byType(AddTripSheet), findsNothing);
    expect(repository.addedTrips, hasLength(1));
    expect(repository.requestedDays, [oct1, oct1]);
  });

  testWidgets('closing the form after a lost connection shows the day of '
      'the trip again: the trip may have been stored', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    }, onAddTrip: (_) async => const Result.error(Failure.timeout()));
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _openForm(tester);
    await _fillEveningTrip(tester);
    await _save(tester);

    await _tap(tester, find.byTooltip('Закрыть'));

    expect(find.byType(AddTripSheet), findsNothing);
    expect(repository.requestedDays, [oct1, oct1]);
  });

  testWidgets('an end time before the start time puts the end on the next '
      'day (D2)', (tester) async {
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);

    await _pickTime(tester, 'Начало', 23, 50);
    await _pickTime(tester, 'Окончание', 0, 20);

    expect(
      _inSheet(
        find.bySemanticsLabel('Окончание, день 2 октября, следующий день'),
      ),
      findsOneWidget,
    );
    expect(_inSheet(find.text('+1 день')), findsOneWidget);
    expect(
      _inSheet(find.bySemanticsLabel('Начало, день 1 октября')),
      findsOneWidget,
    );
  });

  testWidgets('an end two days after the start is marked the same way as '
      'in the list', (tester) async {
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);

    await _tap(tester, _picker('Окончание', 'день'));
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('3'),
      ),
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();

    expect(_inSheet(find.text('+2 дня')), findsOneWidget);
    expect(
      _inSheet(find.bySemanticsLabel('Окончание, день 3 октября, через 2 дня')),
      findsOneWidget,
    );
  });

  testWidgets('every rejected «Сохранить» vibrates, even with the same '
      'errors', (tester) async {
    await pumpApp(tester, FakeTripsRepository.withReports({}));
    await tester.pumpAndSettle();
    await _openForm(tester);
    final haptics = _recordHaptics(tester);

    await _save(tester);
    await _save(tester);

    expect(haptics, List.filled(2, 'HapticFeedbackType.heavyImpact'));
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
    expect(
      inLiveRegion(tester, find.bySemanticsLabel('Поездка сохраняется')),
      isTrue,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            _inSheet(find.widgetWithIcon(IconButton, Icons.close)),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: _moneyField('Сумма'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0.5,
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

    await _tap(tester, _picker('Начало', 'время'));
    expect(
      find.text('Начало'),
      findsNWidgets(2),
      reason: 'the sheet is titled',
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

    await _tap(tester, _picker('Окончание', 'время'));

    final dialog = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(dialog.initialTime, const TimeOfDay(hour: 18, minute: 40));
  });

  testWidgets(
    'a tap outside a money field hides the keyboard',
    (tester) async {
      await pumpApp(tester, FakeTripsRepository.withReports({}));
      await tester.pumpAndSettle();
      await _openForm(tester);

      for (final outside in ['Новая поездка', 'Наличные']) {
        await _tap(tester, _moneyField('Сумма'));
        expect(_typingIn(tester, 'Сумма'), _typing);

        await _tap(tester, _inSheet(find.text(outside)));

        expect(_typingIn(tester, 'Сумма'), _notTyping, reason: outside);
      }
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  for (final (picker, button) in [
    ('day', RegExp('^Начало, день ')),
    ('time', RegExp('^Начало, время ')),
  ]) {
    testWidgets('the keyboard stays hidden after the $picker picker, opened '
        'by a tap or by VoiceOver', (tester) async {
      await pumpApp(tester, FakeTripsRepository.withReports({}));
      await tester.pumpAndSettle();
      await _openForm(tester);

      for (final (opener, open) in <(String, Future<void> Function())>[
        ('a tap', () => _tap(tester, _inSheet(find.bySemanticsLabel(button)))),
        (
          'VoiceOver',
          () async {
            tester.semantics.tap(find.semantics.byLabel(button));
            await tester.pumpAndSettle();
          },
        ),
      ]) {
        await _tap(tester, _moneyField('Сумма'));
        expect(_typingIn(tester, 'Сумма'), _typing);

        await open();
        await _tap(tester, find.text('Готово'));

        expect(_typingIn(tester, 'Сумма'), _notTyping, reason: opener);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

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
        expect(
          _paymentDirection(tester),
          Axis.vertical,
          reason: '«Наличные» does not fit half the row and would break',
        );
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

      testWidgets('«Сохранить» stays above the number keyboard', (
        tester,
      ) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, FakeTripsRepository.withReports({}));
        await tester.pumpAndSettle();
        await _openForm(tester);
        await _tap(tester, _moneyField('Комиссия'));
        tester.view.viewInsets = const FakeViewPadding(
          bottom: _numberPadOnSmallPhone,
        );
        await tester.pumpAndSettle();

        final keyboardTop =
            (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
            tester.view.devicePixelRatio;
        final save = _inSheet(find.text('Сохранить'));
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(keyboardTop));
        expect(_moneyField('Комиссия').hitTestable(), findsOneWidget);
        expect(_typingIn(tester, 'Комиссия'), _typing);

        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(
          _inSheet(find.text('Введите комиссию, если её нет — 0')),
          findsOneWidget,
        );
        expect(_typingIn(tester, 'Комиссия'), _notTyping);
      });

      testWidgets(
        'the time picker',
        (tester) async {
          useSmallPhone(tester, brightness: brightness, textScale: 2);
          await pumpApp(tester, FakeTripsRepository.withReports({}));
          await tester.pumpAndSettle();
          await _openForm(tester);

          await _tap(tester, _picker('Начало', 'время'));

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

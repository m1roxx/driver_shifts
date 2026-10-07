import 'package:freezed_annotation/freezed_annotation.dart';

part 'period.freezed.dart';

enum PeriodKind { week, month }

@freezed
abstract class Period with _$Period {
  @Assert(
    'start == DateTime.utc(start.year, start.month, start.day) && '
        '(kind == PeriodKind.week ? start.weekday == DateTime.monday '
        ': start.day == 1)',
    'A period starts on a Monday or on the 1st, DateTime.utc(y, m, d): '
        'use Period.containing',
  )
  factory Period({required PeriodKind kind, required DateTime start}) = _Period;

  const Period._();

  factory Period.containing(PeriodKind kind, DateTime day) => switch (kind) {
    PeriodKind.week => Period(
      kind: kind,
      start: DateTime.utc(day.year, day.month, day.day - day.weekday + 1),
    ),
    PeriodKind.month => Period(
      kind: kind,
      start: DateTime.utc(day.year, day.month),
    ),
  };

  static final DateTime firstDay = DateTime.utc(1, 1, 2);
  static final DateTime lastDay = DateTime.utc(9999, 12, 30);

  static Period first(PeriodKind kind) {
    final period = Period.containing(kind, firstDay);
    return period.start.isBefore(firstDay) ? period.next : period;
  }

  static Period last(PeriodKind kind) {
    final period = Period.containing(kind, lastDay);
    return period.end.isAfter(lastDay) ? period.previous : period;
  }

  DateTime get end => switch (kind) {
    PeriodKind.week => DateTime.utc(start.year, start.month, start.day + 6),
    PeriodKind.month => DateTime.utc(start.year, start.month + 1, 0),
  };

  Period get next => shifted(1);

  Period get previous => shifted(-1);

  Period shifted(int periods) => switch (kind) {
    PeriodKind.week => Period(
      kind: kind,
      start: DateTime.utc(start.year, start.month, start.day + 7 * periods),
    ),
    PeriodKind.month => Period(
      kind: kind,
      start: DateTime.utc(start.year, start.month + periods),
    ),
  };

  int periodsSince(Period other) => switch (kind) {
    PeriodKind.week => start.difference(other.start).inDays ~/ 7,
    PeriodKind.month =>
      (start.year - other.start.year) * 12 + start.month - other.start.month,
  };

  bool contains(DateTime day) => !day.isBefore(start) && !day.isAfter(end);

  DateTime dayFor(DateTime today) => contains(today) ? today : start;
}

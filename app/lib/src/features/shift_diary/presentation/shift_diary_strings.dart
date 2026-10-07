import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:intl/intl.dart';

abstract final class ShiftDiaryStrings {
  static const String title = 'Дневник смен';
  static const String today = 'Сегодня';
  static const String goToToday = 'Перейти к сегодня';
  static const String yesterday = 'Вчера';
  static const String tomorrow = 'Завтра';
  static const String previousDay = 'Предыдущий день';
  static const String nextDay = 'Следующий день';
  static const String pickDate = 'Выбрать дату';
  static const String done = 'Готово';
  static const String net = 'На руки';
  static const String tripsCount = 'Поездки';
  static const String revenue = 'Выручка';
  static const String commission = 'Комиссия';
  static const String noTrips = 'В этот день поездок нет';
  static const String dayLoadFailedTitle = 'Не удалось загрузить поездки';
  static const String tripSaved = 'Поездка добавлена';
  static const String retry = 'Повторить';
  static const String loading = 'Загрузка поездок';
  static const String serverWaking =
      'Сервер просыпается после простоя — это занимает до минуты';
  static const String addTrip = 'Добавить поездку';
  static const String newTrip = 'Новая поездка';
  static const String close = 'Закрыть';
  static const String start = 'Начало';
  static const String end = 'Окончание';
  static const String time = 'Время';
  static const String amount = 'Сумма';
  static const String paymentMethod = 'Способ оплаты';
  static const String save = 'Сохранить';
  static const String saving = 'Поездка сохраняется';
  static const String tengeSign = '₸';
  static const String viewMode = 'Период сводки';
  static const String day = 'День';
  static const String week = 'Неделя';
  static const String month = 'Месяц';
  static const String byDay = 'По дням';
  static const String noTripsOnDay = 'Нет поездок';
  static const String periodLoadFailedTitle = 'Не удалось загрузить сводку';
  static const String openDay = 'открыть день';

  static String currentPeriod(PeriodKind kind) => switch (kind) {
    PeriodKind.week => 'Эта неделя',
    PeriodKind.month => 'Этот месяц',
  };

  static String previousPeriod(PeriodKind kind) => switch (kind) {
    PeriodKind.week => 'Предыдущая неделя',
    PeriodKind.month => 'Предыдущий месяц',
  };

  static String nextPeriod(PeriodKind kind) => switch (kind) {
    PeriodKind.week => 'Следующая неделя',
    PeriodKind.month => 'Следующий месяц',
  };

  static String noTripsInPeriod(PeriodKind kind) => switch (kind) {
    PeriodKind.week => 'За эту неделю поездок нет',
    PeriodKind.month => 'За этот месяц поездок нет',
  };

  static String weekdayAndDate(
    String weekday,
    String dayAndMonth, {
    bool keepTogether = true,
  }) =>
      '$weekday, '
      '${keepTogether ? dayAndMonth.replaceAll(' ', '\u00A0') : dayAndMonth}';

  static String weekRange(String start, String end) => '$start\u00A0– $end';

  static String spokenPeriodDay(String day, int tripsCount, int netAmount) =>
      '$day: ${tripsCount == 0 ? noTripsOnDay.toLowerCase() : tripsCountOf(tripsCount)}, '
      '${spokenMoney(net.toLowerCase(), netAmount)}';

  static String payment(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => 'Наличные',
    PaymentMethod.card => 'Карта',
  };

  static String tripTimes(String start, String end) => '$start\u00A0– $end';

  static String tripsCountOf(int count) => Intl.plural(
    count,
    one: '$count\u00A0поездка',
    few: '$count\u00A0поездки',
    many: '$count\u00A0поездок',
    other: '$count\u00A0поездки',
    locale: 'ru',
  );

  static String tripPayment(PaymentMethod method) =>
      '${payment(method)}\u00A0·';

  static String tripCommission(int amount) =>
      '${commission.toLowerCase()} ${formatTenge(amount)}';

  static String spokenTripTimes(String start, String end) => 'с $start до $end';

  static String laterDayBadge(int days) => Intl.plural(
    days,
    one: '+$days день',
    few: '+$days дня',
    many: '+$days дней',
    other: '+$days дня',
    locale: 'ru',
  );

  static String spokenTripTimesLater(String start, String end, int days) =>
      days == 1
      ? 'с $start до $end следующего дня'
      : 'с $start до $end ${_inDays(days)}';

  static String spokenLaterDays(int days) =>
      days == 1 ? 'следующий день' : _inDays(days);

  static String _inDays(int days) => Intl.plural(
    days,
    one: 'через $days день',
    few: 'через $days дня',
    many: 'через $days дней',
    other: 'через $days дня',
    locale: 'ru',
  );

  static String spokenTrip({
    required String times,
    required PaymentMethod method,
    required int amount,
    required int commissionAmount,
  }) =>
      '${toBeginningOfSentenceCase(times, 'ru')}, '
      '${payment(method).toLowerCase()}, ${spokenTenge(amount)}, '
      '${commission.toLowerCase()} ${spokenTenge(commissionAmount)}';

  static String spokenMoney(String label, int amount) =>
      '$label ${spokenTenge(amount)}';

  static String spokenNet(int net, int tripsCount) =>
      '${spokenMoney(ShiftDiaryStrings.net, net)}, ${tripsCountOf(tripsCount)}';

  static String spokenFailure(String title, String message) =>
      '$title. $message';

  static String inTenge(String field) => '$field в тенге';

  static String clockTime(int hour, int minute) =>
      '${_twoDigits(hour)}:${_twoDigits(minute)}';

  static String spokenDay(String field, String day, {int laterDays = 0}) =>
      '$field, день $day'
      '${laterDays > 0 ? ', ${spokenLaterDays(laterDays)}' : ''}';

  static String spokenTime(String field, String? time) =>
      '$field, время ${time ?? 'не выбрано'}';

  static String fieldError(TripField field, TripFieldError error) =>
      switch ((field, error)) {
        (TripField.start, TripFieldError.missing) => 'Выберите время начала',
        (TripField.end, TripFieldError.missing) => 'Выберите время окончания',
        (TripField.end, TripFieldError.notAfterStart) =>
          'Окончание должно быть позже начала',
        (TripField.amount, TripFieldError.missing) => 'Введите сумму',
        (TripField.amount, TripFieldError.notPositive) =>
          'Сумма должна быть больше нуля',
        (TripField.amount, TripFieldError.tooLarge) => 'Слишком большая сумма',
        (TripField.commission, TripFieldError.missing) =>
          'Введите комиссию, если её нет — 0',
        (TripField.commission, TripFieldError.negative) =>
          'Комиссия не может быть меньше нуля',
        (TripField.commission, TripFieldError.aboveAmount) =>
          'Комиссия не может быть больше суммы',
        (TripField.payment, TripFieldError.missing) =>
          'Выберите наличные или карту',
        (TripField.start, _) => 'Проверьте начало поездки',
        (TripField.end, _) => 'Проверьте окончание поездки',
        (TripField.amount, _) => 'Проверьте сумму',
        (TripField.commission, _) => 'Проверьте комиссию',
        (TripField.payment, _) => 'Проверьте способ оплаты',
      };

  static String _twoDigits(int number) => '$number'.padLeft(2, '0');
}

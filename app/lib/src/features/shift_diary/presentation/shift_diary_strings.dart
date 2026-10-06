import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';

abstract final class ShiftDiaryStrings {
  static const String title = 'Дневник смен';
  static const String today = 'Сегодня';
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
  static const String retry = 'Повторить';
  static const String loading = 'Загрузка поездок';

  static String payment(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => 'Наличные',
    PaymentMethod.card => 'Карта',
  };

  static String tripTimes(String start, String end) => '$start\u00A0– $end';

  static String spokenTripTimes(String start, String end) => 'с $start до $end';
}

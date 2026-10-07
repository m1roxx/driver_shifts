import 'package:intl/intl.dart';

final NumberFormat _groupedDigits = NumberFormat.decimalPattern('ru');

String groupDigits(int number) => _groupedDigits.format(number);

String formatTenge(int amount) => '${groupDigits(amount)}\u00A0₸';

String spokenTenge(int amount) => '${groupDigits(amount)} тенге';

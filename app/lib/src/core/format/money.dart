import 'package:intl/intl.dart';

final NumberFormat _groupedDigits = NumberFormat.decimalPattern('ru');

String formatTenge(int amount) => '${_groupedDigits.format(amount)}\u00A0₸';

String spokenTenge(int amount) => '${_groupedDigits.format(amount)} тенге';

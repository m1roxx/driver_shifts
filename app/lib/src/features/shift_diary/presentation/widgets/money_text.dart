import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:flutter/widgets.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style});

  final int amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatTenge(amount),
      style: (style ?? const TextStyle()).merge(AppTextStyles.tabularFigures),
      semanticsLabel: spokenTenge(amount),
    );
  }
}

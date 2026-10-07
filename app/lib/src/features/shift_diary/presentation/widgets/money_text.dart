import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:flutter/widgets.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style, this.textScaler});

  final int amount;
  final TextStyle? style;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        formatTenge(amount),
        style: (style ?? const TextStyle()).merge(AppTextStyles.tabularFigures),
        textScaler: textScaler,
        maxLines: 1,
        softWrap: false,
        semanticsLabel: spokenTenge(amount),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

final TonalPalette _cash = TonalPalette.of(150, 36);
final TonalPalette _card = TonalPalette.of(260, 36);

const int _containerTone = 90;
const int _onContainerTone = 30;

@immutable
class PaymentColors extends ThemeExtension<PaymentColors> {
  const PaymentColors({
    required this.cashContainer,
    required this.onCashContainer,
    required this.cardContainer,
    required this.onCardContainer,
  });

  factory PaymentColors.of(Brightness brightness) {
    final (container, onContainer) = switch (brightness) {
      Brightness.light => (_containerTone, _onContainerTone),
      Brightness.dark => (_onContainerTone, _containerTone),
    };
    return PaymentColors(
      cashContainer: Color(_cash.get(container)),
      onCashContainer: Color(_cash.get(onContainer)),
      cardContainer: Color(_card.get(container)),
      onCardContainer: Color(_card.get(onContainer)),
    );
  }

  final Color cashContainer;
  final Color onCashContainer;
  final Color cardContainer;
  final Color onCardContainer;

  @override
  PaymentColors copyWith({
    Color? cashContainer,
    Color? onCashContainer,
    Color? cardContainer,
    Color? onCardContainer,
  }) => PaymentColors(
    cashContainer: cashContainer ?? this.cashContainer,
    onCashContainer: onCashContainer ?? this.onCashContainer,
    cardContainer: cardContainer ?? this.cardContainer,
    onCardContainer: onCardContainer ?? this.onCardContainer,
  );

  @override
  PaymentColors lerp(PaymentColors? other, double t) {
    if (other == null) return this;
    return PaymentColors(
      cashContainer: Color.lerp(cashContainer, other.cashContainer, t)!,
      onCashContainer: Color.lerp(onCashContainer, other.onCashContainer, t)!,
      cardContainer: Color.lerp(cardContainer, other.cardContainer, t)!,
      onCardContainer: Color.lerp(onCardContainer, other.onCardContainer, t)!,
    );
  }
}

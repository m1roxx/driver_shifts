import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/payment_colors.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:flutter/material.dart';

class PaymentAvatar extends StatelessWidget {
  const PaymentAvatar(this.method, {super.key, this.small = false});

  final PaymentMethod method;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PaymentColors>()!;
    final (icon, background, foreground) = switch (method) {
      PaymentMethod.cash => (
        AppIcons.cash,
        colors.cashContainer,
        colors.onCashContainer,
      ),
      PaymentMethod.card => (
        AppIcons.card,
        colors.cardContainer,
        colors.onCardContainer,
      ),
    };
    final size = small ? Sizes.smallAvatar : Sizes.tripAvatar;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: foreground,
          size: small ? Sizes.smallAvatarIcon : Sizes.tripAvatarIcon,
        ),
      ),
    );
  }
}

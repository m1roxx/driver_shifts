import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/state_message.dart';
import 'package:flutter/material.dart';

class DayFailureView extends StatelessWidget {
  const DayFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icons = AppIcons.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: StateMessage(
              icon: failureIcon(failure, icons),
              iconBackground: colors.errorContainer,
              iconColor: colors.onErrorContainer,
              title: ShiftDiaryStrings.dayLoadFailedTitle,
              message: failure.message,
              liveLabel: ShiftDiaryStrings.spokenDayFailure(failure.message),
              action: FilledButton.tonalIcon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.square(Sizes.touchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(Radii.large),
                    ),
                  ),
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                ),
                icon: Icon(icons.retry),
                label: const Text(ShiftDiaryStrings.retry),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

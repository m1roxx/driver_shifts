import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/slow_load_note.dart';
import 'package:flutter/material.dart';

class RefreshStatusSliver extends StatelessWidget {
  const RefreshStatusSliver({
    super.key,
    required this.failure,
    required this.slow,
    required this.onRetry,
  });

  final Failure? failure;
  final bool slow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      sliver: SliverToBoxAdapter(
        child: AnimatedSize(
          duration: Motion.of(context, Motion.resize),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: switch (failure) {
            final failure? => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: FailureBanner(failure: failure, onRetry: onRetry),
            ),
            null when slow => const Padding(
              padding: EdgeInsets.only(bottom: Spacing.sm),
              child: SlowLoadNote(),
            ),
            null => const SizedBox(width: double.infinity),
          },
        ),
      ),
    );
  }
}

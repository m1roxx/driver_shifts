import 'dart:async';

import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlidingSegmentedControl<T> extends StatelessWidget {
  const SlidingSegmentedControl({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final index = values.indexOf(selected);
    final position = values.length == 1
        ? 0.0
        : -1 + 2 * index / (values.length - 1);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: dark
            ? colors.surfaceContainerLow
            : colors.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxs),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(position, 0),
                duration: Motion.of(context, Motion.resize),
                curve: Motion.curve,
                child: FractionallySizedBox(
                  widthFactor: 1 / values.length,
                  heightFactor: 1,
                  child: Material(
                    shape: const StadiumBorder(),
                    color: dark
                        ? colors.surfaceContainerHighest
                        : colors.surfaceContainerLowest,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: theme.shadowColor,
                    elevation: Sizes.segmentThumbElevation,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final value in values)
                  Expanded(
                    child: _Segment(
                      label: labelOf(value),
                      selected: value == selected,
                      onTap: () {
                        if (value == selected) return;
                        unawaited(HapticFeedback.selectionClick());
                        onChanged(value);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = selected
        ? AppTextStyles.strong(theme.textTheme.labelLarge)
        : AppTextStyles.medium(theme.textTheme.labelLarge);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.segmentedControl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: Motion.of(context, Motion.fast),
                  style: (style ?? const TextStyle()).copyWith(
                    color: selected
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                  child: Text(label, maxLines: 1, softWrap: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

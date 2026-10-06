import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:flutter/widgets.dart';

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - Spacing.md) / 2;
        return Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.md,
          children: [
            for (final child in children)
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: columnWidth),
                child: child,
              ),
          ],
        );
      },
    );
  }
}

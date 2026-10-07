import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/metric_grid.dart';
import 'package:flutter/material.dart';

const String _labelSample = ShiftDiaryStrings.commission;
const int _amountSample = 10000;
const String _timeSample = '00:00';
final String _amountText = formatTenge(_amountSample);
final String _timesText = ShiftDiaryStrings.tripTimes(_timeSample, _timeSample);

class DaySkeleton extends StatelessWidget {
  const DaySkeleton({super.key});

  static const int _metrics = 4;
  static const int _trips = 3;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final metric = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Bone(Text(_labelSample, style: textTheme.labelLarge)),
        const SizedBox(height: Spacing.xs),
        _Bone(Text(_amountText, style: textTheme.titleLarge)),
      ],
    );
    return Semantics(
      label: ShiftDiaryStrings.loading,
      child: ExcludeSemantics(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(
                        Text(
                          ShiftDiaryStrings.net,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      _Bone(Text(_amountText, style: textTheme.headlineLarge)),
                      const SizedBox(height: Spacing.md),
                      MetricGrid(
                        children: [for (var i = 0; i < _metrics; i++) metric],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (var i = 0; i < _trips; i++)
              ListTile(
                leading: const _Bone(Icon(Icons.payments_outlined)),
                title: _Bone(Text(_timesText, style: textTheme.bodyLarge)),
                subtitle: _Bone(
                  Text(_labelSample, style: textTheme.bodyMedium),
                ),
                trailing: _Bone(
                  Text(_amountText, style: textTheme.titleMedium),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone(this.sample);

  final Widget sample;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: Visibility.maintain(visible: false, child: sample),
      ),
    );
  }
}

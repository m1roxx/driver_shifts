import 'dart:async';

import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';

const int _amountSample = 10000;
const String _timeSample = '00:00';
const int _trips = 3;
final String _amountText = formatTenge(_amountSample);
final String _timesText = ShiftDiaryStrings.tripTimes(_timeSample, _timeSample);
final String _detailsText =
    '${ShiftDiaryStrings.tripPayment(PaymentMethod.cash)} '
    '${ShiftDiaryStrings.tripCommission(_amountSample)}';

class DaySkeleton extends StatefulWidget {
  const DaySkeleton({super.key});

  @override
  State<DaySkeleton> createState() => _DaySkeletonState();
}

class _DaySkeletonState extends State<DaySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.skeletonPulse,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: Opacities.skeletonDimmed,
  ).animate(_pulse);
  Timer? _delay;
  var _shown = false;
  var _animate = true;

  @override
  void initState() {
    super.initState();
    _delay = Timer(Motion.skeletonDelay, () {
      setState(() => _shown = true);
      _syncPulse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    _syncPulse();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse() {
    if (_shown && _animate) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat(reverse: true));
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) return const SizedBox.expand();
    return Semantics(
      liveRegion: true,
      label: ShiftDiaryStrings.loading,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              0,
              Spacing.md,
              Spacing.md,
            ),
            children: const [_SummaryBones(), _HeaderBone(), _TripBones()],
          ),
        ),
      ),
    );
  }
}

class _SummaryBones extends StatelessWidget {
  const _SummaryBones();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget row(String label) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: Spacing.md,
      runSpacing: Spacing.sm,
      children: [
        _Bone(Text(label, style: textTheme.bodyLarge)),
        _Bone(Text(_amountText, style: textTheme.bodyLarge)),
      ],
    );
    final paymentBone = _Bone(
      Text(_amountText, style: textTheme.titleLarge),
      expand: true,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.sml,
          children: [
            row(ShiftDiaryStrings.revenue),
            row(ShiftDiaryStrings.commission),
            _Bone(Text(ShiftDiaryStrings.net, style: textTheme.labelLarge)),
            _Bone(
              Text(
                _amountText,
                style: AppTextStyles.heroAmount(textTheme),
                textScaler: TextScale.headline(context),
              ),
            ),
            _Bone(
              Text(
                ShiftDiaryStrings.tripsCountOf(_trips),
                style: textTheme.bodyMedium,
              ),
            ),
            if (TextScale.isLarge(context)) ...[
              paymentBone,
              paymentBone,
            ] else
              Row(
                spacing: Spacing.md,
                children: [
                  Expanded(child: paymentBone),
                  Expanded(child: paymentBone),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBone extends StatelessWidget {
  const _HeaderBone();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
      ),
      child: _Bone(
        Text(
          ShiftDiaryStrings.tripsCount,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _TripBones extends StatelessWidget {
  const _TripBones();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final large = TextScale.isLarge(context);
    final texts = [
      _Bone(Text(_timesText, style: textTheme.bodyLarge)),
      _Bone(Text(_detailsText, style: textTheme.bodyMedium)),
    ];
    final amount = _Bone(Text(_amountText, style: textTheme.bodyLarge));
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < _trips; i++)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.tripRow),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: large
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spacing.xs,
                        children: [...texts, amount],
                      )
                    : Row(
                        spacing: Spacing.md,
                        children: [
                          const _Bone(
                            SizedBox.square(dimension: Sizes.tripAvatar),
                            circle: true,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: Spacing.xs,
                              children: texts,
                            ),
                          ),
                          amount,
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone(this.sample, {this.expand = false, this.circle = false});

  final Widget sample;
  final bool expand;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final bone = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : const BorderRadius.all(Radius.circular(Radii.small)),
      ),
      child: Visibility.maintain(visible: false, child: sample),
    );
    if (expand) return bone;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: bone,
    );
  }
}

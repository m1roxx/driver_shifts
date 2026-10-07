import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:flutter/material.dart';

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.message,
    this.liveLabel,
    this.action,
  });

  final IconData icon;
  final Color? iconBackground;
  final Color iconColor;
  final String title;
  final String? message;
  final String? liveLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
    final liveLabel = this.liveLabel;
    final action = this.action;
    final texts = Column(
      spacing: Spacing.sm,
      children: [
        Text(
          title,
          style: AppTextStyles.strong(theme.textTheme.titleLarge),
          textAlign: TextAlign.center,
        ),
        if (message != null)
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.md,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: Sizes.stateAvatar,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: Sizes.stateAvatarIcon,
                  color: iconColor,
                ),
              ),
            ),
          ),
          if (liveLabel == null)
            texts
          else
            Semantics(
              container: true,
              liveRegion: true,
              label: liveLabel,
              excludeSemantics: true,
              child: texts,
            ),
          ?action,
        ],
      ),
    );
  }
}

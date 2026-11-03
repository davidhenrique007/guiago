import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Visual weight of a task row. Drives the colored edge and the
/// status icon, so priority and completion read at a glance
/// (master spec §22: "qual é a próxima coisa importante?").
enum AppTaskCardTone { low, medium, high, done }

/// A task row: time, title, status line and a status icon, with a
/// colored left edge. The design system stays free of feature code,
/// so the caller maps its own priority/status onto [tone] and
/// supplies the already-formatted [time] and [statusLabel].
class AppTaskCard extends StatelessWidget {
  const AppTaskCard({
    required this.time,
    required this.title,
    required this.statusLabel,
    this.tone = AppTaskCardTone.low,
    this.onTap,
    super.key,
  });

  final String time;
  final String title;
  final String statusLabel;
  final AppTaskCardTone tone;
  final VoidCallback? onTap;

  bool get _isDone => tone == AppTaskCardTone.done;

  Color get _edgeColor => switch (tone) {
        AppTaskCardTone.low => AppColors.border,
        AppTaskCardTone.medium => AppColors.warning,
        AppTaskCardTone.high => AppColors.error,
        AppTaskCardTone.done => AppColors.success,
      };

  Color get _iconColor => switch (tone) {
        AppTaskCardTone.low => AppColors.textSecondary,
        AppTaskCardTone.medium => AppColors.warning,
        AppTaskCardTone.high => AppColors.error,
        AppTaskCardTone.done => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    // A non-uniform Border cannot be combined with a borderRadius, so
    // the colored edge is a real child clipped by the rounded card.
    final Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ColoredBox(
              color: _edgeColor,
              child: const SizedBox(width: 3),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2,
                  vertical: 13,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 46,
                      child: Text(
                        time,
                        style: AppTypography.mono.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            title,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _isDone
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: _isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusLabel,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: _isDone
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      _isDone
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: _iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget animated = AnimatedOpacity(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      opacity: _isDone ? 0.75 : 1,
      child: card,
    );

    final Widget labelled = Semantics(
      container: true,
      label: '$time, $title, $statusLabel',
      child: ExcludeSemantics(child: animated),
    );

    if (onTap == null) return labelled;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: labelled,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// "‹  Sábado, 21 de novembro  ›": moves the selected day one day back
/// or forward, so any day (past or future) is one tap away.
class CalendarDayNavigator extends StatelessWidget {
  const CalendarDayNavigator({
    required this.day,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: l10n.previousDay,
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Expanded(
          child: Text(
            l10n.longDate(day),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
        IconButton(
          tooltip: l10n.nextDay,
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

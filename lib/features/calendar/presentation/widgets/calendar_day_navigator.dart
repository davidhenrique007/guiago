import 'package:flutter/material.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';

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
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Dia anterior',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Expanded(
          child: Text(
            PtDateLabels.longDate(day),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
        IconButton(
          tooltip: 'Dia seguinte',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

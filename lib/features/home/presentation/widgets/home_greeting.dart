import 'package:flutter/material.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';

/// Saudação + data (master spec §22).
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({required this.userName, required this.today, super.key});

  final String userName;
  final DateTime today;

  String get _period {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 19) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _dateLabel => PtDateLabels.longDate(today);

  @override
  Widget build(BuildContext context) {
    final String suffix = userName.trim().isEmpty ? '' : ', $userName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$_period$suffix', style: AppTypography.displayLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(_dateLabel, style: AppTypography.bodyMedium),
      ],
    );
  }
}

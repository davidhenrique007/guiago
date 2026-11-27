import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// Saudação + data (master spec §22).
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({required this.userName, required this.today, super.key});

  final String userName;
  final DateTime today;

  String _period(AppLocalizations l10n) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 19) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String suffix = userName.trim().isEmpty ? '' : ', $userName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${_period(l10n)}$suffix', style: AppTypography.displayLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.longDate(today), style: AppTypography.bodyMedium),
      ],
    );
  }
}

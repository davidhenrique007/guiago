import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Saudação + data (master spec §22).
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({required this.userName, required this.today, super.key});

  final String userName;
  final DateTime today;

  static const List<String> _weekdays = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  static const List<String> _months = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  String get _period {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 19) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _dateLabel {
    final String weekday = _weekdays[today.weekday - 1];
    final String month = _months[today.month - 1];
    return '${_capitalize(weekday)}, ${today.day} de $month';
  }

  static String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';

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

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// "Concluir" / "Adiar" quick actions of a pending task on the Home.
/// "Adiar" only appears once the task is due ([canSnooze]).
class HomeTaskActionButtons extends StatelessWidget {
  const HomeTaskActionButtons({
    required this.canSnooze,
    required this.onComplete,
    required this.onSnooze,
    super.key,
  });

  final bool canSnooze;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (canSnooze)
          TextButton(
            onPressed: onSnooze,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text('Adiar', style: AppTypography.label),
          ),
        TextButton(
          onPressed: onComplete,
          style: TextButton.styleFrom(foregroundColor: AppColors.success),
          child: Text('Concluir', style: AppTypography.label),
        ),
      ],
    );
  }
}

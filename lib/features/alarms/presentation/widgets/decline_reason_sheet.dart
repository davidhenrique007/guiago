import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/decline_reason.dart';

/// Shows the "Não vou, porquê?" bottom sheet (master spec §24) and
/// returns the chosen [DeclineReason], or `null` if dismissed.
Future<DeclineReason?> showDeclineReasonSheet(BuildContext context) {
  return showModalBottomSheet<DeclineReason>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (BuildContext context) => const _DeclineReasonSheetContent(),
  );
}

class _DeclineReasonSheetContent extends StatelessWidget {
  const _DeclineReasonSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Porque não vai fazer isto agora?',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final DeclineReason reason in DeclineReason.values)
              ListTile(
                title: Text(reason.label, style: AppTypography.bodyLarge),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
      ),
    );
  }
}

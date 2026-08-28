import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';

/// GuiaGo's confirmation dialog. Used for destructive/important
/// confirmations (e.g. "delete task", "não vou" reason — §24).
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.confirmLabel,
    this.message,
    this.cancelLabel = 'Cancelar',
    super.key,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;

  /// Shows the dialog and returns `true` if confirmed, `false`/`null`
  /// otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    String cancelLabel = 'Cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: AppTypography.titleLarge),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

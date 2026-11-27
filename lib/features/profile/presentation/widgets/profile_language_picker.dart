import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_language.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom sheet to choose Português / English. Tapping a row chooses
/// it and closes the sheet; returns the choice, or null when dismissed.
abstract final class ProfileLanguagePicker {
  static Future<AppLanguage?> show(
    BuildContext context, {
    required AppLanguage selected,
  }) {
    return AppBottomSheet.show<AppLanguage>(
      context,
      title: context.l10n.rowLanguage,
      child: Builder(
        builder: (BuildContext sheetContext) => Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final AppLanguage language in AppLanguage.values)
                InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(language),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          language == selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: language == selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(language.label, style: AppTypography.bodyLarge),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

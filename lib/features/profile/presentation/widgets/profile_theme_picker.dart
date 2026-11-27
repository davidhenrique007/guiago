import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_mode.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom sheet to choose Claro / Escuro / Sistema. Tapping a row
/// chooses it and closes the sheet; returns the choice, or null when
/// dismissed.
abstract final class ProfileThemePicker {
  /// The name of [mode] in the language of [l10n].
  static String themeModeLabel(AppLocalizations l10n, AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.system => l10n.themeSystem,
        AppThemeMode.light => l10n.themeLight,
        AppThemeMode.dark => l10n.themeDark,
      };

  static Future<AppThemeMode?> show(
    BuildContext context, {
    required AppThemeMode selected,
  }) {
    return AppBottomSheet.show<AppThemeMode>(
      context,
      title: context.l10n.rowTheme,
      child: Builder(
        builder: (BuildContext sheetContext) => Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final AppThemeMode mode in <AppThemeMode>[
                AppThemeMode.light,
                AppThemeMode.dark,
                AppThemeMode.system,
              ])
                InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(mode),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          mode == selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: mode == selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          themeModeLabel(sheetContext.l10n, mode),
                          style: AppTypography.bodyLarge,
                        ),
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

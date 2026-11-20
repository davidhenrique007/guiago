import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// What the user can do with a pending task from the Tasks tab.
enum TaskItemAction { edit, remove }

/// Bottom sheet with "Editar" and "Apagar" for one task.
abstract final class TaskItemActionsSheet {
  static Future<TaskItemAction?> show(
    BuildContext context, {
    required String title,
  }) {
    return AppBottomSheet.show<TaskItemAction>(
      context,
      title: title,
      // AppBottomSheet paints its background on a DecoratedBox, which
      // would hide the ListTile ink: give the tiles their own Material.
      child: Builder(
        builder: (BuildContext sheetContext) => Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text('Editar', style: AppTypography.bodyLarge),
                onTap: () =>
                    Navigator.of(sheetContext).pop(TaskItemAction.edit),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Apagar',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(TaskItemAction.remove),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../tasks/presentation/widgets/task_create_minutes_selector.dart';
import '../../../tasks/presentation/widgets/task_create_options.dart';

/// Bottom sheet to pick a number of minutes (snooze or tolerance).
/// Returns the chosen value, or null when dismissed. Tapping a chip
/// picks it and closes the sheet.
abstract final class ProfileMinutesPicker {
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required List<int> options,
    required int selected,
  }) {
    return AppBottomSheet.show<int>(
      context,
      title: title,
      child: Builder(
        builder: (BuildContext sheetContext) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TaskCreateMinutesSelector(
            // Keep a value saved earlier that is not in the list.
            options: TaskCreateOptions.including(options, selected),
            selected: selected,
            onChanged: (int minutes) => Navigator.of(sheetContext).pop(minutes),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// What the user chose in the profile photo sheet.
enum ProfilePhotoAction { camera, gallery, remove }

/// Bottom sheet: take a photo, choose from the gallery or (when there is
/// one) remove the current photo. Returns null when dismissed.
abstract final class ProfilePhotoSheet {
  static Future<ProfilePhotoAction?> show(
    BuildContext context, {
    required bool hasPhoto,
  }) {
    return AppBottomSheet.show<ProfilePhotoAction>(
      context,
      title: context.l10n.photoTitle,
      child: Builder(
        builder: (BuildContext sheetContext) {
          final AppLocalizations l10n = sheetContext.l10n;
          return Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Row(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.photoCamera,
                  action: ProfilePhotoAction.camera,
                ),
                _Row(
                  icon: Icons.photo_library_outlined,
                  label: l10n.photoGallery,
                  action: ProfilePhotoAction.gallery,
                ),
                if (hasPhoto)
                  _Row(
                    icon: Icons.delete_outline,
                    label: l10n.photoRemove,
                    action: ProfilePhotoAction.remove,
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.action});

  final IconData icon;
  final String label;
  final ProfilePhotoAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(action),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.bodyLarge),
          ],
        ),
      ),
    );
  }
}

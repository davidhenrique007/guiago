import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/domain/settings.dart';
import 'profile_avatar.dart';

/// Initial in a circle, the user's name and their main objective.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.settings,
    this.onEdit,
    this.onPhotoTap,
    super.key,
  });

  final Settings settings;

  /// Shows an edit button when set.
  final VoidCallback? onEdit;

  /// Makes the avatar tappable (change / remove the photo) when set.
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final String name = settings.userName.trim();
    final String objective = settings.mainObjective.trim();

    return Row(
      children: <Widget>[
        _avatar(context, name),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name.isEmpty ? context.l10n.profileNoName : name,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                objective.isEmpty ? context.l10n.profileNoObjective : objective,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            tooltip: context.l10n.profileEditTitle,
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _avatar(BuildContext context, String name) {
    final Widget avatar = ProfileAvatar(
      name: name,
      photoPath: settings.photoPath,
    );
    if (onPhotoTap == null) return avatar;
    return Tooltip(
      message: context.l10n.photoChange,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPhotoTap,
        child: avatar,
      ),
    );
  }
}

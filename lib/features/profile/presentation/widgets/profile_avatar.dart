import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// The user's photo in a circle, or their initial when there is no photo
/// (or the file is gone).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.photoPath,
    this.size = 64,
    super.key,
  });

  final String name;
  final String photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String trimmed = name.trim();
    final Widget initial = Text(
      trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
      style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
    );
    final bool hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.primary),
      ),
      child: hasPhoto
          ? Image.file(
              File(photoPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initial,
            )
          : initial,
    );
  }
}

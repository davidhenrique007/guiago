import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// One destination of [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// GuiaGo's bottom navigation bar: icon + short label, an emerald dot
/// above the selected destination. A custom widget instead of
/// Material's [NavigationBar] so the bar keeps the product's flat,
/// bordered look (master spec §7) and stays free of Material 3's
/// pill indicator.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    isSelected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isSelected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.standard,
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

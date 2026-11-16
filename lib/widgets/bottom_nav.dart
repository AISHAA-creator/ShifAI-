import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScan,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              Expanded(child: _ScanNavButton(onTap: onScan)),
              _NavItem(
                icon: Icons.show_chart_rounded,
                label: 'Trends',
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanNavButton extends StatelessWidget {
  const _ScanNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: AppColors.secondary,
                    shape: const CircleBorder(),
                    elevation: 8,
                    shadowColor: AppColors.secondary.withValues(alpha: 0.3),
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.document_scanner_outlined,
                        color: AppColors.onPrimary,
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Scan',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

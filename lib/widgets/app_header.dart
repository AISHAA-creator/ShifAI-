import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.title, this.onProfileTap});

  final String title;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthProvider>().isSignedIn;
    final compactStatus = MediaQuery.sizeOf(context).width < 400;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.screenHorizontal,
      title: Row(
        children: [
          Image.asset(
            'assets/images/shifai_logo.png',
            width: 68,
            height: 24,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'ShifAI',
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isSignedIn
                      ? compactStatus
                            ? 'Private'
                            : 'Private account'
                      : compactStatus
                      ? 'Local'
                      : 'Local-only',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: IconButton(
            tooltip: 'Profile',
            onPressed: onProfileTap,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

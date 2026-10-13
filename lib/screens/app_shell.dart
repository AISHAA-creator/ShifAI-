import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import '../utils/open_add_result.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trends_screen.dart';

/// Home / Scan / Trends / Profile bar from the Stitch design. Scan opens the
/// add-result flow instead of being a tab of its own.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return Scaffold(
      body: IndexedStack(
        index: nav.tab,
        children: const [HomeScreen(), TrendsScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: _BottomBar(
        current: nav.tab,
        onTab: nav.setTab,
        onScan: () => openAddResult(context),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;

  const _BottomBar({
    required this.current,
    required this.onTab,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.pastelBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                selected: current == 0,
                onTap: () => onTab(0),
              ),
              Expanded(
                child: InkWell(
                  onTap: onScan,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.buttonBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.buttonBlue.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Scan',
                        style: TextStyle(fontSize: 12, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.show_chart_rounded,
                label: 'Trends',
                selected: current == 1,
                onTap: () => onTab(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: current == 2,
                onTap: () => onTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.buttonBlue : AppColors.gray;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

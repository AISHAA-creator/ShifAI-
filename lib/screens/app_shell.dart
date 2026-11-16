import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_provider.dart';
import '../utils/open_add_result.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trends_screen.dart';

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
      bottomNavigationBar: BottomNav(
        currentIndex: nav.tab,
        onTabSelected: nav.setTab,
        onScan: () => openAddResult(context),
      ),
    );
  }
}

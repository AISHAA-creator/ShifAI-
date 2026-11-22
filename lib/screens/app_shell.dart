import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/coaching_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../utils/open_add_result.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trends_screen.dart';
import '../l10n/tx.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final records = context.watch<LabRecordsProvider>();
    final coaching = context.watch<CoachingProvider>();
    final syncError = records.syncError ?? coaching.syncError;
    return Scaffold(
      body: Column(
        children: [
          if (syncError case final error?)
            MaterialBanner(
              content: Tx(error),
              leading: const Icon(Icons.cloud_off_outlined),
              actions: [
                TextButton(
                  onPressed: () {
                    records.clearSyncError();
                    coaching.clearSyncError();
                  },
                  child: const Tx('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: nav.tab,
              children: const [HomeScreen(), TrendsScreen(), ProfileScreen()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: nav.tab,
        onTabSelected: nav.setTab,
        onScan: () => openAddResult(context),
      ),
    );
  }
}

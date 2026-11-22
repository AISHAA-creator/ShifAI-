import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../utils/share_summary.dart';
import '../widgets/ds_widgets.dart';
import 'checkin_screen.dart';
import 'emergency_screen.dart';
import 'find_doctor_screen.dart';
import 'lab_entry_form_screen.dart';
import 'medicine_screen.dart';
import 'notifications_screen.dart';
import 'profile_form_screen.dart';
import 'search_screen.dart';
import 'skin_check_screen.dart';
import 'wellness_screen.dart';
import '../l10n/tx.dart';

/// "Show all" of the quick actions: every feature in one place.
class ShortcutsScreen extends StatelessWidget {
  const ShortcutsScreen({super.key});

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _tab(BuildContext context, int tab) {
    context.read<NavProvider>().setTab(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final labs = context.read<LabRecordsProvider>();

    final items = <(IconData, String, String, VoidCallback, Color)>[
      (
        Icons.document_scanner_outlined,
        'Scan a report',
        'Read a lab report from a photo',
        () => openAddResult(context),
        DS.navy,
      ),
      (
        Icons.edit_outlined,
        'Type in a result',
        'Enter the values yourself',
        () => _go(context, const LabEntryFormScreen()),
        DS.navy,
      ),
      (
        Icons.show_chart_rounded,
        'Trends',
        'Your results over time',
        () => _tab(context, 1),
        DS.navy,
      ),
      (
        Icons.share_outlined,
        'Share',
        'Send a summary on WhatsApp',
        () {
          if (labs.records.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Tx('Add a result first, then you can share it.'),
              ),
            );
          } else {
            shareSummaryOnWhatsApp(context, labs.records.last);
          }
        },
        DS.navy,
      ),
      (
        Icons.restaurant_outlined,
        'Eat and move',
        'Food and activity guidance',
        () => _go(context, const WellnessScreen()),
        DS.navy,
      ),
      (
        Icons.bolt_rounded,
        'Meals and energy',
        'Your own food and energy pattern',
        () => _go(context, const CheckInScreen()),
        DS.navy,
      ),
      (
        Icons.accessibility_new_rounded,
        'Skin and body check',
        'Signs of insulin resistance',
        () => _go(context, const SkinCheckScreen()),
        DS.navy,
      ),
      (
        Icons.medical_services_outlined,
        'Find a doctor',
        'Book an appointment',
        () => _go(context, const FindDoctorScreen()),
        DS.navy,
      ),
      (
        Icons.medication_outlined,
        'Medicine',
        'Your daily schedule',
        () => _go(context, const MedicineScreen()),
        DS.navy,
      ),
      (
        Icons.straighten_rounded,
        'My measurements',
        'Age, height, weight, waist',
        () => _go(context, const ProfileFormScreen()),
        DS.navy,
      ),
      (
        Icons.search_rounded,
        'Search',
        'Find anything in the app',
        () => _go(context, const SearchScreen()),
        DS.navy,
      ),
      (
        Icons.notifications_none_rounded,
        'Notifications',
        'Reminders and updates',
        () => _go(context, const NotificationsScreen()),
        DS.navy,
      ),
      (
        Icons.emergency_outlined,
        'Emergency',
        'Call for help',
        () => _go(context, const EmergencyScreen()),
        DS.emergency,
      ),
    ];

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 28),
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: DsBackButton(),
              ),
              const SizedBox(height: 26),
              const DsTitle('All', 'shortcuts', size: 36),
              const SizedBox(height: 22),
              for (final item in items) ...[
                DsCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  onTap: item.$4,
                  child: Row(
                    children: [
                      DsIconBadge(
                        icon: item.$1,
                        size: 46,
                        color: item.$5,
                        background: item.$5 == DS.emergency
                            ? DS.redTint
                            : DS.skyTint,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tx(
                              item.$2,
                              style: DS.text(size: 16, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Tx(
                              item.$3,
                              style: DS.text(
                                size: 13.5,
                                weight: FontWeight.w500,
                                color: DS.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: DS.iconMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

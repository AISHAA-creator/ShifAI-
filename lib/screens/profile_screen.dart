import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../providers/auth_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SizedBox(height: 8),
          const Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.pastel,
              child: Icon(
                Icons.person_outline_rounded,
                size: 44,
                color: AppColors.buttonBlue,
              ),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              auth.isSignedIn ? auth.displayName : 'Local-only preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
          if (auth.email != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                auth.email!,
                style: const TextStyle(color: AppColors.gray),
              ),
            ),
          ],
          if (auth.isSignedIn) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _importLocalRecords(context),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Import local-only results'),
            ),
          ],
          SizedBox(height: 22),
          _MeasurementsCard(),
          SizedBox(height: 10),
          _InfoCard(
            icon: auth.isSignedIn
                ? Icons.cloud_done_outlined
                : Icons.phone_android,
            title: auth.isSignedIn
                ? 'Account-backed storage'
                : 'Local-only storage',
            text: auth.isSignedIn
                ? 'Your confirmed lab values sync to your Supabase account and '
                      'remain cached on this device for offline access. Your '
                      'body measurements stay on this device.'
                : 'No account or cloud connection is active. Results remain '
                      'on this device and are not uploaded.',
          ),
          SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Units are handled for you',
            text:
                'Glucose in g/L, mg/dL or mmol/L and insulin in µIU/mL or '
                'pmol/L are converted automatically.',
          ),
          SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.info_outline,
            title: 'About ShifAI',
            text:
                'ShifAI is a risk-awareness tool, not a diagnosis. Always '
                'confirm results with your doctor.',
          ),
          if (auth.isSignedIn) ...[
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: auth.busy
                  ? null
                  : () async {
                      try {
                        await context.read<AuthProvider>().signOut();
                      } on AuthException catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      } on ClientException {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not reach Supabase. Try again when online.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.logout),
              label: Text(auth.busy ? 'Signing out…' : 'Sign out'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importLocalRecords(BuildContext context) async {
    final provider = context.read<LabRecordsProvider>();
    final count = await provider.guestRecordCount();
    if (!context.mounted) return;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no local-only results to import.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import local results?'),
        content: Text(
          '$count local result${count == 1 ? '' : 's'} will be copied to this '
          'signed-in account. Existing account records will not be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final imported = await provider.importGuestRecordsToAccount();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported == 0
                ? 'Those local results are already in this account.'
                : provider.syncError == null
                ? '$imported result${imported == 1 ? '' : 's'} synced to this account.'
                : '$imported result${imported == 1 ? '' : 's'} saved locally; cloud sync will retry.',
          ),
        ),
      );
    }
  }
}

class _MeasurementsCard extends StatelessWidget {
  const _MeasurementsCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final p = provider.profile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.pastel,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.buttonBlue,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Your measurements',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileFormScreen(),
                    ),
                  ),
                  child: Text(p == null ? 'Add' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p == null)
              const Text(
                'Add your age, height, weight and waist to get an insulin '
                'resistance risk estimate. No blood test needed.',
                style: TextStyle(
                  color: AppColors.gray,
                  height: 1.35,
                  fontSize: 13.5,
                ),
              )
            else ...[
              Text(
                '${p.female ? 'Female' : 'Male'}, ${p.age} years  •  '
                '${p.heightCm.toStringAsFixed(0)} cm  •  ${p.weightKg.toStringAsFixed(0)} kg  •  '
                'waist ${p.waistCm.toStringAsFixed(0)} cm',
                style: const TextStyle(
                  color: AppColors.text,
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BMI ${p.bmi.toStringAsFixed(1)}  •  waist-to-height ${p.waistToHeight.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.gray, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.pastel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.buttonBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.gray,
                      height: 1.35,
                      fontSize: 13.5,
                    ),
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

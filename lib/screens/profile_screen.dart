import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: const [
          SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.pastel,
              child: Icon(Icons.person_outline_rounded, size: 44, color: AppColors.buttonBlue),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Text('Your ShifAI',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ),
          SizedBox(height: 22),
          _MeasurementsCard(),
          SizedBox(height: 10),
          _InfoCard(
            icon: Icons.lock_outline,
            title: 'Private and on-device',
            text: 'Your results and measurements are stored only on this device. '
                'Nothing is uploaded unless you choose to share a summary.',
          ),
          SizedBox(height: 10),
          _InfoCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Units are handled for you',
            text: 'Glucose in g/L, mg/dL or mmol/L and insulin in µIU/mL or '
                'pmol/L are converted automatically.',
          ),
          SizedBox(height: 10),
          _InfoCard(
            icon: Icons.info_outline,
            title: 'About ShifAI',
            text: 'ShifAI is a risk-awareness tool, not a diagnosis. Always '
                'confirm results with your doctor.',
          ),
        ],
      ),
    );
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
                  child: const Icon(Icons.straighten_rounded, color: AppColors.buttonBlue),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Your measurements',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.navy, fontSize: 15)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
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
                style: TextStyle(color: AppColors.gray, height: 1.35, fontSize: 13.5),
              )
            else ...[
              Text(
                '${p.female ? 'Female' : 'Male'}, ${p.age} years  •  '
                '${p.heightCm.toStringAsFixed(0)} cm  •  ${p.weightKg.toStringAsFixed(0)} kg  •  '
                'waist ${p.waistCm.toStringAsFixed(0)} cm',
                style: const TextStyle(color: AppColors.text, height: 1.4, fontSize: 13.5),
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
  const _InfoCard({required this.icon, required this.title, required this.text});

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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 3),
                  Text(text,
                      style: const TextStyle(color: AppColors.gray, height: 1.35, fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

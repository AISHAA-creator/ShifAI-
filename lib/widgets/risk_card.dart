import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../screens/profile_form_screen.dart';
import '../theme/app_colors.dart';
import 'risk_gauge.dart';

/// "Insulin Resistance Risk" card from the Stitch dashboard, backed by the
/// NHANES-trained model. Works with no lab results at all.
class RiskCard extends StatelessWidget {
  const RiskCard({super.key});

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    if (provider.loading) return const SizedBox.shrink();

    final assessment = provider.assessment;
    final model = provider.model;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: assessment == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'METABOLIC ASSESSMENT',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.1,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Insulin Resistance Risk',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get an estimate from your age, height, weight and waist. '
                    'No blood test needed.',
                    style: TextStyle(color: AppColors.gray, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _openForm(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buttonBlue,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add my measurements'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'METABOLIC ASSESSMENT',
                              style: TextStyle(
                                fontSize: 11.5,
                                letterSpacing: 1.1,
                                color: AppColors.gray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Insulin Resistance Risk',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Based on waist-to-height ratio, BMI, age and sex.',
                              style: TextStyle(color: AppColors.gray, height: 1.35, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            RiskChip(band: assessment.band),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      RiskGauge(assessment: assessment),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.pastel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Estimated chance that your HOMA-IR is 2.9 or higher.',
                            style: TextStyle(color: AppColors.text, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openForm(context),
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ),
                  if (model != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Trained on ${_thousands(model.trainedOn)} adults from the US NHANES '
                      'health survey. It may be less accurate for other populations. '
                      'A lab test is the real answer.',
                      style: const TextStyle(color: AppColors.gray, fontSize: 12, height: 1.4),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String _thousands(int n) {
    final s = n.toString();
    return s.length > 3 ? '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}' : s;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';

/// Age, sex, height, weight and waist: everything the risk estimate needs,
/// none of it requiring a blood test.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  bool _female = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    String fmt(num? v) => v == null ? '' : v.toString();
    _age = TextEditingController(text: fmt(p?.age));
    _height = TextEditingController(text: fmt(p?.heightCm));
    _weight = TextEditingController(text: fmt(p?.weightKg));
    _waist = TextEditingController(text: fmt(p?.waistCm));
    _female = p?.female ?? true;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _waist.dispose();
    super.dispose();
  }

  String? _range(String? value, double min, double max, String unit) {
    final v = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (v == null) return 'Required';
    if (v < min || v > max) return 'Enter ${min.toInt()}–${max.toInt()} $unit';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    double num(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));

    final profile = UserProfile(
      age: num(_age).round(),
      female: _female,
      heightCm: num(_height),
      weightKg: num(_weight),
      waistCm: num(_waist),
    );
    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    await provider.save(profile);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your measurements')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pastel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.buttonBlue,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No blood test needed. These stay on your device and are '
                      'only used to estimate your risk.',
                      style: TextStyle(
                        color: AppColors.text,
                        height: 1.35,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sex',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Female')),
                ButtonSegment(value: false, label: Text('Male')),
              ],
              selected: {_female},
              onSelectionChanged: (s) => setState(() => _female = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 18),
            _field(
              _age,
              'Age',
              'years',
              (v) => _range(v, 18, 90, 'years'),
              digitsOnly: true,
            ),
            const SizedBox(height: 14),
            _field(_height, 'Height', 'cm', (v) => _range(v, 120, 230, 'cm')),
            const SizedBox(height: 14),
            _field(_weight, 'Weight', 'kg', (v) => _range(v, 30, 250, 'kg')),
            const SizedBox(height: 14),
            _field(_waist, 'Waist', 'cm', (v) => _range(v, 40, 200, 'cm')),
            const SizedBox(height: 6),
            const Text(
              'Measure your waist at navel level, relaxed, after a normal breath out.',
              style: TextStyle(color: AppColors.gray, fontSize: 12.5),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.buttonBlue,
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save & see my estimate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String unit,
    String? Function(String?) validator, {
    bool digitsOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !digitsOnly),
      validator: validator,
      decoration: InputDecoration(labelText: label, suffixText: unit),
    );
  }
}

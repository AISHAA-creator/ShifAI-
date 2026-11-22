import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/settings_provider.dart';
import '../theme/ds.dart';
import '../widgets/city_picker.dart';
import '../widgets/ds_widgets.dart';
import 'book_screen.dart';
import '../l10n/tx.dart';

/// Step after a high result (or from Home): doctors in the chosen city.
/// The list is sample data until a real directory of verified doctors exists.
class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  static const _specialties = ['Endocrinologist', 'General', 'Nutrition'];
  String _specialty = _specialties.first;

  @override
  Widget build(BuildContext context) {
    final city = context.watch<SettingsProvider>().city;
    final doctors = doctorsIn(city, specialty: _specialty);

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
              const DsTitle('Find a', 'doctor', size: 36),
              const SizedBox(height: 22),
              Semantics(
                button: true,
                label: 'Change city',
                child: GestureDetector(
                  onTap: () => pickCity(context),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: DS.softShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 22,
                          color: DS.navy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Tx(
                            city ?? 'Choose your city',
                            style: DS.text(
                              weight: FontWeight.w600,
                              color: city == null ? DS.iconMuted : DS.ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 22,
                          color: DS.iconMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in _specialties) ...[
                      Semantics(
                        button: true,
                        selected: s == _specialty,
                        label: s,
                        child: GestureDetector(
                          onTap: () => setState(() => _specialty = s),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: s == _specialty
                                  ? DS.navy
                                  : DS.navy.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Tx(
                              s,
                              style: DS.text(
                                size: 14,
                                weight: s == _specialty
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: s == _specialty
                                    ? Colors.white
                                    : DS.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tx(
                    city == null ? 'Doctors' : 'In $city',
                    style: DS.text(size: 17, weight: FontWeight.w700),
                  ),
                  Tx(
                    'Sample list',
                    style: DS.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: DS.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (city == null)
                DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tx(
                        'Choose your city to see the doctors listed there.',
                        style: DS.text(color: DS.muted, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      DsPrimaryButton(
                        label: 'Choose your city',
                        height: 54,
                        onPressed: () => pickCity(context),
                      ),
                    ],
                  ),
                )
              else if (doctors.isEmpty)
                DsCard(
                  child: Tx(
                    'No $_specialty is listed in $city yet. Doctors will be '
                    'added city by city. Try a bigger city nearby.',
                    style: DS.text(color: DS.muted, height: 1.45),
                  ),
                )
              else
                for (final d in doctors) ...[
                  _DoctorCard(doctor: d),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: DS.navy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tx(
                      'Doctors will be verified before they are listed.',
                      style: DS.text(
                        size: 14,
                        weight: FontWeight.w500,
                        color: DS.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              DsDoctorAvatar(asset: doctor.photo, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tx(
                      doctor.name,
                      style: DS.text(
                        size: 17,
                        weight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Tx(
                      doctor.specialty,
                      style: DS.text(
                        size: 14,
                        weight: FontWeight.w500,
                        color: DS.muted,
                      ),
                    ),
                  ],
                ),
              ),
              DsPill(
                doctor.city,
                background: DS.skyTint,
                foreground: DS.navy,
                vertical: 6,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: DS.muted),
              const SizedBox(width: 7),
              Expanded(
                child: Tx(
                  doctor.nextSlot,
                  style: DS.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Book ${doctor.name}',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookScreen(doctor: doctor),
                    ),
                  ),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DS.navy,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Tx(
                      'Book',
                      style: DS.text(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

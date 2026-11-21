import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/ds.dart';
import '../widgets/band_style.dart';
import '../widgets/ds_widgets.dart';
import 'find_doctor_screen.dart';

/// Shown after "Confirm" on a scanned or typed result. Nothing is saved until
/// the person chooses to save (or to find a doctor, which saves first).
/// A doctor is only suggested when the result is high.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.record});
  final LabRecord record;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saved) return;
    await context.read<LabRecordsProvider>().addRecord(widget.record);
    _saved = true;
  }

  Future<void> _saveAndTrends() async {
    if (_saving) return;
    final nav = context.read<NavProvider>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await _save();
    nav.setTab(1);
    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _findDoctor() async {
    if (_saving) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await _save();
    if (!mounted) return;
    setState(() => _saving = false);
    navigator.push(MaterialPageRoute(builder: (_) => const FindDoctorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final homa = record.homaIr!;
    final band = record.homaIrBand!;
    final high = band == HomaIrBand.significantResistance;

    Widget mini(String label, String value, String unit) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DS.field,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: DS.text(
                size: 12.5,
                weight: FontWeight.w600,
                color: DS.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value ',
                    style: DS.text(size: 18, weight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: unit,
                    style: DS.text(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: DS.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: DsBackButton(),
                    ),
                    const SizedBox(height: 26),
                    const DsTitle('Your', 'result'),
                    const SizedBox(height: 22),
                    DsCard(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 116,
                                height: 116,
                                child: CustomPaint(
                                  painter: _BigRingPainter(
                                    progress: (homa / 4.5).clamp(0.04, 1.0),
                                    color: bandColor(band),
                                    track: bandBackground(band),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          homa.toStringAsFixed(2),
                                          style: DS.text(
                                            size: 30,
                                            weight: FontWeight.w800,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        Text(
                                          'HOMA-IR',
                                          style: DS.text(
                                            size: 12,
                                            weight: FontWeight.w600,
                                            color: DS.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BandChip(band: band, size: 13.5),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Test date: ${DateFormat.yMMMd().format(record.date)}',
                                      style: DS.text(
                                        size: 14,
                                        weight: FontWeight.w500,
                                        color: DS.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              mini(
                                'Glucose',
                                record.fastingGlucoseMgdl!.toStringAsFixed(0),
                                'mg/dL',
                              ),
                              const SizedBox(width: 10),
                              mini(
                                'Insulin',
                                record.fastingInsulinUiuml!.toStringAsFixed(1),
                                'uIU/mL',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (high)
                      _DoctorSuggestion(onFind: _findDoctor)
                    else
                      DsCard(
                        radius: 26,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          bandExplanation(band),
                          style: DS.text(
                            size: 15,
                            weight: FontWeight.w500,
                            color: DS.muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    DsOutlineButton(
                      label: 'Save and see my trends',
                      onPressed: _saving ? null : _saveAndTrends,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A screening estimate, not a diagnosis.',
                      style: DS.text(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: DS.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorSuggestion extends StatelessWidget {
  const _DoctorSuggestion({required this.onFind});
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final city = context.watch<SettingsProvider>().city;
    final nearby = doctorsIn(city);
    final faces = (nearby.isEmpty ? sampleDoctors : nearby).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DS.navyGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: DS.cardShadow(0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -64,
            top: -74,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.sky.withValues(alpha: 0.22),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    for (var i = 0; i < faces.length; i++)
                      Positioned(
                        left: i * 42.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: DS.navy2, width: 3),
                          ),
                          child: DsDoctorAvatar(
                            asset: faces[i].photo,
                            size: 56,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'See a doctor about this result',
                style: DS.text(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                city == null
                    ? 'Endocrinologists near you'
                    : (nearby.isEmpty
                          ? 'Doctors are being added in $city'
                          : '${nearby.length} endocrinologists in $city'),
                style: DS.text(
                  size: 14.5,
                  weight: FontWeight.w500,
                  color: DS.onNavyMuted,
                ),
              ),
              const SizedBox(height: 18),
              Semantics(
                button: true,
                label: 'Find a doctor',
                child: GestureDetector(
                  onTap: onFind,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Find a doctor',
                      style: DS.text(
                        size: 16.5,
                        weight: FontWeight.w700,
                        color: DS.navy,
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

class _BigRingPainter extends CustomPainter {
  _BigRingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BigRingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

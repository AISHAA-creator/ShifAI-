import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';
import '../utils/open_add_result.dart';
import '../utils/platform_helper.dart';
import '../widgets/band_style.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final withHoma = provider.records.where((r) => r.homaIr != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/shifai_logo.png',
          height: 36,
          filterQuality: FilterQuality.high,
          semanticLabel: 'ShifAI',
        ),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: _PrivacyChip()),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Your metabolic snapshot',
                    style: TextStyle(color: AppColors.gray)),
                const SizedBox(height: 18),
                withHoma.isEmpty
                    ? const _WelcomeCard()
                    : _HomaCard(records: withHoma),
                const SizedBox(height: 16),
                const _ScanCard(),
                const SizedBox(height: 26),
                const _CoachingSection(),
                const SizedBox(height: 22),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 15, color: AppColors.gray),
                    SizedBox(width: 6),
                    Text('Your health metrics stay on this device.',
                        style: TextStyle(color: AppColors.gray, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: AppColors.buttonBlue),
          SizedBox(width: 5),
          Text('On-device',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.buttonBlue,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.pastel,
              child: Icon(Icons.favorite_border, color: AppColors.buttonBlue, size: 30),
            ),
            SizedBox(height: 16),
            Text('Welcome to ShifAI',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
            SizedBox(height: 8),
            Text(
              'A quiet companion for your metabolic health — catching risk '
              'early, long before it becomes a diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              'Add your first lab result below to see your HOMA-IR.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomaCard extends StatelessWidget {
  final List<LabRecord> records;
  const _HomaCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final latest = records.last;
    final band = latest.homaIrBand!;
    final recent =
        records.length > 5 ? records.sublist(records.length - 5) : records;
    final values = recent.map((r) => r.homaIr!).toList();

    String? deltaText;
    Color deltaColor = AppColors.gray;
    if (recent.length >= 2) {
      final delta = values.last - values.first;
      final days = recent.last.date.difference(recent.first.date).inDays;
      final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');
      deltaText = '$sign${delta.abs().toStringAsFixed(1)} '
          '${days >= 1 ? 'over $days days' : 'across ${recent.length} tests'}';
      deltaColor = delta <= 0 ? AppColors.safeText : AppColors.dangerText;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VALIDATED BIOMARKER',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1.1,
                    color: AppColors.gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                BandChip(band: band),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your Latest HOMA-IR',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest.homaIr!.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: bandTextColor(band),
                  ),
                ),
                const SizedBox(width: 12),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Optimal range: < 1.9',
                      style: TextStyle(
                          color: AppColors.navy, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pastel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: values.length < 2
                  ? const Text(
                      'Add another result to see your trend here.',
                      style: TextStyle(color: AppColors.gray),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent ${values.length} tests',
                                style: const TextStyle(color: AppColors.gray)),
                            Text(deltaText!,
                                style: TextStyle(
                                    color: deltaColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Sparkline(values: values),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < values.length; i++)
                              Text(
                                values[i].toStringAsFixed(1) +
                                    (i == values.length - 1 ? ' (latest)' : ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: i == values.length - 1
                                      ? AppColors.navy
                                      : AppColors.gray,
                                  fontWeight: i == values.length - 1
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.event_note_outlined,
                    size: 18, color: AppColors.gray),
                const SizedBox(width: 8),
                Text(
                  'Last result: ${DateFormat.yMMMd().format(latest.date)}',
                  style: const TextStyle(color: AppColors.gray, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max(0.3, (hi - lo) * 0.3);

    return SizedBox(
      height: 58,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              color: AppColors.buttonBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: AppColors.buttonBlue,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.pastel,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openAddResult(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.buttonBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isMobilePlatform
                      ? Icons.document_scanner_outlined
                      : Icons.edit_note_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMobilePlatform ? 'Scan a lab report' : 'Add a lab result',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMobilePlatform
                          ? 'Instant HOMA-IR, read on your device'
                          : 'Enter glucose and insulin to get your HOMA-IR',
                      style: const TextStyle(color: AppColors.gray, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_forward, color: AppColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String text;
  const _Tip(this.icon, this.title, this.text);
}

class _CoachingSection extends StatefulWidget {
  const _CoachingSection();

  @override
  State<_CoachingSection> createState() => _CoachingSectionState();
}

class _CoachingSectionState extends State<_CoachingSection> {
  static const _tips = [
    _Tip(
      Icons.directions_walk,
      'Post-meal glucose blunter',
      '10-minute walk after lunch lowers your post-meal glucose spike.',
    ),
    _Tip(
      Icons.grain,
      'Glycemic satiety',
      'Swap refined bread for whole grain or sourdough at dinner tonight.',
    ),
  ];

  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's micro-coaching",
          style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _tips.length; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.pastel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_tips[i].icon, color: AppColors.buttonBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tips[i].title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tips[i].text,
                          style: const TextStyle(
                              color: AppColors.text, height: 1.3, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      if (!_done.remove(i)) _done.add(i);
                    }),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _done.contains(i) ? AppColors.safe : AppColors.pastel,
                      foregroundColor:
                          _done.contains(i) ? Colors.white : AppColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < _tips.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

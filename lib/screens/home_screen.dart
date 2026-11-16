import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import '../utils/open_add_result.dart';
import '../utils/platform_helper.dart';
import '../widgets/app_header.dart';
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
    final withHoma = provider.records
        .where((record) => record.homaIr != null)
        .toList();

    return Scaffold(
      appBar: AppHeader(
        title: 'Dashboard',
        onProfileTap: () => context.read<NavProvider>().setTab(2),
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your metabolic snapshot',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                withHoma.isEmpty
                    ? const _WelcomeCard()
                    : _HomaCard(records: withHoma),
                const SizedBox(height: AppSpacing.lg),
                const _ScanCard(),
                const SizedBox(height: AppSpacing.xl),
                const _CoachingSection(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Your health metrics stay on this device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Icon(
                Icons.favorite_border,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome to ShifAI',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A quiet companion for your metabolic health. Add a lab result '
              'to see your HOMA-IR and follow changes over time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomaCard extends StatelessWidget {
  const _HomaCard({required this.records});

  final List<LabRecord> records;

  @override
  Widget build(BuildContext context) {
    final latest = records.last;
    final band = latest.homaIrBand!;
    final recent = records.length > 5
        ? records.sublist(records.length - 5)
        : records;
    final values = recent.map((record) => record.homaIr!).toList();

    String? deltaText;
    Color deltaColor = AppColors.onSurfaceVariant;
    if (recent.length >= 2) {
      final delta = values.last - values.first;
      final days = recent.last.date.difference(recent.first.date).inDays;
      final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');
      deltaText =
          '$sign${delta.abs().toStringAsFixed(1)} '
          '${days >= 1 ? 'over $days days' : 'across ${recent.length} tests'}';
      deltaColor = delta <= 0 ? AppColors.safeText : AppColors.dangerText;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LATEST HOMA-IR',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Metabolic assessment',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                BandChip(band: band),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest.homaIr!.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.displayMedium
                      ?.copyWith(color: bandTextColor(band)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'Optimal range: < 1.9',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent ${values.length} tests',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (deltaText != null)
                        Flexible(
                          child: Text(
                            deltaText,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: deltaColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                  if (values.length >= 2) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Sparkline(values: values),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < values.length; i++)
                          Flexible(
                            child: Text(
                              '${values[i].toStringAsFixed(1)}'
                              '${i == values.length - 1 ? ' (latest)' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: i == values.length - 1
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: i == values.length - 1
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Add another result to see your trend.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Last result: ${DateFormat.yMMMd().format(latest.date)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
  const _Sparkline({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final padding = math.max(0.3, (high - low) * 0.3);

    return SizedBox(
      height: 58,
      child: LineChart(
        LineChartData(
          minY: low - padding,
          maxY: high + padding,
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
              color: AppColors.secondary,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.surfaceContainerLowest,
                  strokeColor: AppColors.secondary,
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
      color: AppColors.secondaryFixed.withValues(alpha: 0.38),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => openAddResult(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Icon(
                  isMobilePlatform
                      ? Icons.document_scanner_outlined
                      : Icons.edit_note_rounded,
                  color: AppColors.surfaceContainerLowest,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMobilePlatform
                          ? 'Scan a lab report'
                          : 'Add a lab result',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isMobilePlatform
                          ? 'Processed on your device'
                          : 'Enter glucose and insulin to calculate HOMA-IR',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.arrow_forward, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip {
  const _Tip(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

class _CoachingSection extends StatefulWidget {
  const _CoachingSection();

  @override
  State<_CoachingSection> createState() => _CoachingSectionState();
}

class _CoachingSectionState extends State<_CoachingSection> {
  static const tips = [
    _Tip(
      Icons.directions_walk,
      'Post-meal glucose blunter',
      'A 10-minute walk after lunch can help reduce your post-meal glucose spike.',
    ),
    _Tip(
      Icons.grain,
      'Glycemic satiety',
      'Try whole grain or sourdough instead of refined bread at dinner.',
    ),
  ];

  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_outlined, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "Today's micro-coaching",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < tips.length; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    child: Icon(tips[i].icon, color: AppColors.secondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tips[i].title,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          tips[i].text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      if (!_done.remove(i)) _done.add(i);
                    }),
                    icon: Icon(
                      _done.contains(i) ? Icons.check_circle : Icons.check,
                      size: 18,
                    ),
                    label: const Text('Done'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: _done.contains(i)
                          ? AppColors.emerald700
                          : AppColors.surfaceContainer,
                      foregroundColor: _done.contains(i)
                          ? AppColors.surfaceContainerLowest
                          : AppColors.primary,
                      side: BorderSide.none,
                      textStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != tips.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

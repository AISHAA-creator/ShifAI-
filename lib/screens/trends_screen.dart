import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';
import '../utils/open_add_result.dart';
import '../widgets/band_style.dart';

enum TrendMetric { homaIr, glucose, hba1c, insulin }

extension TrendMetricX on TrendMetric {
  String get tab {
    switch (this) {
      case TrendMetric.homaIr:
        return 'HOMA-IR';
      case TrendMetric.glucose:
        return 'Glucose';
      case TrendMetric.hba1c:
        return 'HbA1c';
      case TrendMetric.insulin:
        return 'Insulin';
    }
  }

  String get title {
    switch (this) {
      case TrendMetric.homaIr:
        return 'HOMA-IR';
      case TrendMetric.glucose:
        return 'fasting glucose';
      case TrendMetric.hba1c:
        return 'HbA1c';
      case TrendMetric.insulin:
        return 'fasting insulin';
    }
  }

  String get unit {
    switch (this) {
      case TrendMetric.homaIr:
        return 'index';
      case TrendMetric.glucose:
        return 'mg/dL';
      case TrendMetric.hba1c:
        return '%';
      case TrendMetric.insulin:
        return 'µIU/mL';
    }
  }

  int get decimals => this == TrendMetric.glucose ? 0 : (this == TrendMetric.homaIr ? 2 : 1);

  double? valueOf(LabRecord r) {
    switch (this) {
      case TrendMetric.homaIr:
        return r.homaIr;
      case TrendMetric.glucose:
        return r.fastingGlucoseMgdl;
      case TrendMetric.hba1c:
        return r.hba1cPercent;
      case TrendMetric.insulin:
        return r.fastingInsulinUiuml;
    }
  }
}

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendMetric _metric = TrendMetric.homaIr;

  Future<void> _shareSummary(LabRecord latest) async {
    final text = StringBuffer('My ShifAI summary\n');
    if (latest.homaIr != null) {
      text.writeln('HOMA-IR: ${latest.homaIr!.toStringAsFixed(2)} '
          '(${latest.homaIrBand!.label}) on ${DateFormat.yMMMd().format(latest.date)}');
    } else {
      text.writeln('Result from ${DateFormat.yMMMd().format(latest.date)}');
    }
    if (latest.fastingGlucoseMgdl != null) {
      text.writeln('Fasting glucose: ${latest.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL');
    }
    if (latest.fastingInsulinUiuml != null) {
      text.writeln('Fasting insulin: ${latest.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL');
    }
    if (latest.hba1cPercent != null) {
      text.writeln('HbA1c: ${latest.hba1cPercent!.toStringAsFixed(1)}%');
    }
    text.write('Screening tool only, not medical advice.');

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text.toString())}');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open WhatsApp on this device.")),
      );
    }
  }

  Future<void> _confirmDelete(LabRecord record) async {
    final provider = context.read<LabRecordsProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this result?'),
        content: const Text('It will be removed from your history on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deleteRecord(record.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final all = provider.records;
    final withHoma = all.where((r) => r.homaIr != null).toList();
    final series = all.where((r) => _metric.valueOf(r) != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Metabolic Trends')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
              ? const _EmptyTrends()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    if (withHoma.isNotEmpty)
                      _ScoreCard(first: withHoma.first, latest: withHoma.last)
                    else
                      const _NoHomaCard(),
                    const SizedBox(height: 16),
                    _MetricTabs(
                      selected: _metric,
                      onChanged: (m) => setState(() => _metric = m),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(metric: _metric, series: series),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => openAddResult(context),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('Add Another Result'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.buttonBlue,
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _shareSummary(all.last),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share Summary on WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.safeBg,
                        foregroundColor: AppColors.safeText,
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'All results',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),
                    for (final r in all.reversed) ...[
                      _RecordTile(record: r, onDelete: () => _confirmDelete(r)),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Screening tool only, not medical advice. Always review results '
                      'and treatment with your doctor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyTrends extends StatelessWidget {
  const _EmptyTrends();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded, size: 52, color: AppColors.accentBlue),
            SizedBox(height: 12),
            Text('No results yet',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            SizedBox(height: 6),
            Text(
              'Add a lab result and your HOMA-IR trend will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoHomaCard extends StatelessWidget {
  const _NoHomaCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Add fasting glucose and fasting insulin together to calculate your HOMA-IR score.',
          style: TextStyle(color: AppColors.gray, height: 1.4),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final LabRecord first;
  final LabRecord latest;
  const _ScoreCard({required this.first, required this.latest});

  @override
  Widget build(BuildContext context) {
    final band = latest.homaIrBand!;
    final value = latest.homaIr!;
    final hasDelta = !identical(first, latest);
    final delta = value - first.homaIr!;

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
                  'HOMA-IR SCORE',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray,
                  ),
                ),
                BandChip(band: band),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: bandTextColor(band),
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('index', style: TextStyle(color: AppColors.gray)),
                ),
                const Spacer(),
                if (hasDelta)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          delta <= 0 ? Icons.south_east_rounded : Icons.north_east_rounded,
                          size: 16,
                          color: delta <= 0 ? AppColors.safeText : AppColors.dangerText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${delta > 0 ? '+' : (delta < 0 ? '−' : '')}${delta.abs().toStringAsFixed(2)} since first',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: delta <= 0 ? AppColors.safeText : AppColors.dangerText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _ScaleBar(value: value),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pastel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.spa_outlined, color: AppColors.buttonBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bandExplanation(band),
                      style: const TextStyle(color: AppColors.text, height: 1.4),
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

class _ScaleBar extends StatelessWidget {
  final double value;
  const _ScaleBar({required this.value});

  static const double _max = 4.5;
  static const _marks = <(double, String)>[
    (0, '0'),
    (1.0, '1.0'),
    (1.9, '1.9'),
    (2.9, '2.9'),
    (4.5, '4.5+'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double x(double v) => (v / _max).clamp(0.0, 1.0) * w;

      Widget seg(int flex, Color color) => Expanded(
            flex: flex,
            child: Container(height: 10, color: color),
          );

      return SizedBox(
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    seg(100, const Color(0xFFBFEBD5)),
                    seg(90, const Color(0xFFDDF3E5)),
                    seg(100, const Color(0xFFFBE7A6)),
                    seg(160, const Color(0xFFF8C9C9)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: x(value) - 8,
              top: 7,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: bandColor(
                    value < 1.0
                        ? HomaIrBand.optimal
                        : value < 1.9
                            ? HomaIrBand.normal
                            : value < 2.9
                                ? HomaIrBand.earlyResistance
                                : HomaIrBand.significantResistance,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                ),
              ),
            ),
            for (final m in _marks)
              Positioned(
                left: (x(m.$1) - 20).clamp(0.0, math.max(0.0, w - 40)),
                top: 32,
                width: 40,
                child: Text(
                  m.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.gray),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _MetricTabs extends StatelessWidget {
  final TrendMetric selected;
  final ValueChanged<TrendMetric> onChanged;
  const _MetricTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final m in TrendMetric.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m.tab,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: m == selected ? FontWeight.w700 : FontWeight.w500,
                      color: m == selected ? AppColors.navy : AppColors.gray,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final TrendMetric metric;
  final List<LabRecord> series;
  const _ChartCard({required this.metric, required this.series});

  @override
  Widget build(BuildContext context) {
    final values = series.map((r) => metric.valueOf(r)!).toList();
    final n = values.length;

    double? pct;
    if (n >= 2 && values.first != 0) {
      pct = (values.last - values.first) / values.first * 100;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        'Your ${metric.title} over time',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n == 1 ? '1 recorded lab checkup' : '$n recorded lab checkups',
                        style: const TextStyle(color: AppColors.gray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (pct != null && pct.abs() >= 0.5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pct < 0 ? AppColors.safeBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${pct < 0 ? 'Down' : 'Up'} ${pct.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: pct < 0 ? AppColors.safeText : AppColors.warningText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (n == 0)
              const Text(
                'No results with this value yet.',
                style: TextStyle(color: AppColors.gray),
              )
            else ...[
              _LatestCallout(metric: metric, record: series.last, value: values.last),
              const SizedBox(height: 16),
              if (n < 2)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pastel,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Add one more result with this value to see your trend line.',
                    style: TextStyle(color: AppColors.gray),
                  ),
                )
              else ...[
                SizedBox(height: 200, child: _TrendChart(metric: metric, series: series)),
                if (metric == TrendMetric.homaIr) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Green band: target zone (below 1.9)',
                    style: TextStyle(color: AppColors.gray, fontSize: 12),
                  ),
                ],
                if (pct != null && pct.abs() >= 0.5) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.pastel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pct < 0 ? Icons.trending_down : Icons.trending_up,
                          color: AppColors.buttonBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pct < 0
                                ? 'Down ${pct.abs().toStringAsFixed(0)}% since your first result. '
                                    'Keep going with what is working.'
                                : 'Up ${pct.abs().toStringAsFixed(0)}% since your first result. '
                                    'If it keeps rising, mention it to your doctor.',
                            style: const TextStyle(color: AppColors.text, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LatestCallout extends StatelessWidget {
  final TrendMetric metric;
  final LabRecord record;
  final double value;
  const _LatestCallout({required this.metric, required this.record, required this.value});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (record.fastingGlucoseMgdl != null)
        'Glucose ${record.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
      if (record.fastingInsulinUiuml != null)
        'Insulin ${record.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL',
      if (record.hba1cPercent != null) 'HbA1c ${record.hba1cPercent!.toStringAsFixed(1)}%',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.buttonBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat.MMMd().format(record.date)}: '
            '${value.toStringAsFixed(metric.decimals)} ${metric.unit}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              parts.join('  •  '),
              style: const TextStyle(color: Color(0xFFBBD7F0), fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final TrendMetric metric;
  final List<LabRecord> series;
  const _TrendChart({required this.metric, required this.series});

  @override
  Widget build(BuildContext context) {
    final values = series.map((r) => metric.valueOf(r)!).toList();
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, hi.abs() * 0.05 + 0.1);

    final isHoma = metric == TrendMetric.homaIr;
    final minY = isHoma ? 0.0 : math.max(0.0, lo - pad);
    final maxY = isHoma ? math.max(hi + pad, 2.6) : hi + pad;
    final yInterval = math.max((maxY - minY) / 4, 0.1);
    final xInterval = math.max(1, (series.length / 5).ceil()).toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.pastelBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (isHoma)
              HorizontalRangeAnnotation(
                y1: 0,
                y2: 1.9,
                color: AppColors.safe.withValues(alpha: 0.16),
              ),
          ],
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: yInterval,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(metric.decimals == 0 ? 0 : 1),
                style: const TextStyle(color: AppColors.gray, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (v != i || i < 0 || i >= series.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Md().format(series[i].date),
                    style: const TextStyle(color: AppColors.gray, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            color: AppColors.buttonBlue,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, _, bar, index) => FlDotCirclePainter(
                radius: index == values.length - 1 ? 6 : 4.5,
                color: index == values.length - 1 ? AppColors.warning : Colors.white,
                strokeColor: AppColors.buttonBlue,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final LabRecord record;
  final VoidCallback onDelete;
  const _RecordTile({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final band = record.homaIrBand;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: band == null ? AppColors.pastel : bandBackground(band),
                border: Border.all(
                  color: band == null ? AppColors.pastelBorder : bandColor(band),
                  width: 2.5,
                ),
              ),
              child: band == null
                  ? const Icon(Icons.science_outlined, color: AppColors.buttonBlue)
                  : Text(
                      record.homaIr!.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: bandTextColor(band),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd().format(record.date),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  const SizedBox(height: 2),
                  if (record.fastingGlucoseMgdl != null)
                    Text('Glucose: ${record.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
                  if (record.fastingInsulinUiuml != null)
                    Text('Insulin: ${record.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
                  if (record.hba1cPercent != null)
                    Text('HbA1c: ${record.hba1cPercent!.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete result',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../providers/checkin_provider.dart';
import '../services/pattern_miner.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import '../l10n/tx.dart';
import '../l10n/translator.dart';

/// Log a meal and, about 90 minutes later, how your energy is. ShifAI then
/// looks for your own pattern. Everything stays on this phone.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late MealKind _kind = _defaultKind();
  CarbLevel? _carb;
  int? _energy;
  bool _craving = false;

  static MealKind _defaultKind() {
    final h = DateTime.now().hour;
    if (h < 11) return MealKind.breakfast;
    if (h < 16) return MealKind.lunch;
    if (h < 22) return MealKind.dinner;
    return MealKind.snack;
  }

  void _saved(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Tx(message)));
  }

  Future<void> _saveMeal() async {
    final carb = _carb;
    if (carb == null) return;
    await context.read<CheckInProvider>().addMeal(_kind, carb);
    if (!mounted) return;
    setState(() => _carb = null);
    _saved('Meal saved. Check your energy in about 90 minutes.');
  }

  Future<void> _saveEnergy() async {
    final energy = _energy;
    if (energy == null) return;
    await context.read<CheckInProvider>().addEnergy(energy, _craving);
    if (!mounted) return;
    setState(() {
      _energy = null;
      _craving = false;
    });
    _saved('Energy saved.');
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DS.navy : DS.field,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Tx(
          label,
          style: DS.text(
            size: 14,
            weight: FontWeight.w700,
            color: selected ? Colors.white : DS.muted,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CheckInProvider>();
    final insights = data.insights;

    final recent = <({DateTime time, Widget row})>[
      for (final m in data.meals)
        (
          time: m.time,
          row: _EntryRow(
            icon: Icons.restaurant_outlined,
            title: '${m.kind.label}, ${m.carb.label.toLowerCase()}',
            time: m.time,
            onRemove: () => data.removeMeal(m.id),
          ),
        ),
      for (final f in data.feelings)
        (
          time: f.time,
          row: _EntryRow(
            icon: Icons.bolt_rounded,
            title:
                'Energy: ${energyLabels[f.energy]!.toLowerCase()}'
                '${f.craving ? ', craving sweets' : ''}',
            time: f.time,
            onRemove: () => data.removeEnergy(f.id),
          ),
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 32),
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: DsBackButton(),
              ),
              const SizedBox(height: 26),
              const DsTitle('Meals and', 'energy', size: 36),
              const SizedBox(height: 14),
              Tx(
                'Log a meal, then your energy about 90 minutes later. ShifAI '
                'finds your own pattern. Stays on this phone.',
                style: DS.text(
                  size: 15.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Tx(
                '1. What did you eat?',
                style: DS.text(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DsCard(
                radius: 26,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in MealKind.values)
                          _chip(k.label, k == _kind, () {
                            setState(() => _kind = k);
                          }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final c in CarbLevel.values) ...[
                      Semantics(
                        button: true,
                        selected: c == _carb,
                        label: c.label,
                        child: GestureDetector(
                          onTap: () => setState(() => _carb = c),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c == _carb ? DS.skyTint : DS.field,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: c == _carb
                                    ? DS.navy
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tx(
                                  c.label,
                                  style: DS.text(
                                    size: 15.5,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Tx(
                                  c.detail,
                                  style: DS.text(
                                    size: 13.5,
                                    weight: FontWeight.w500,
                                    color: DS.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),
                    DsPrimaryButton(
                      label: 'Save meal',
                      height: 54,
                      onPressed: _carb == null ? null : _saveMeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Tx(
                '2. How is your energy now?',
                style: DS.text(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DsCard(
                radius: 26,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final e in energyLabels.entries) ...[
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: _energy == e.key,
                              label: 'Energy ${e.key}, ${e.value}',
                              child: GestureDetector(
                                onTap: () => setState(() => _energy = e.key),
                                child: Container(
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _energy == e.key
                                        ? DS.navy
                                        : DS.field,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tx(
                                        '${e.key}',
                                        style: DS.text(
                                          size: 20,
                                          weight: FontWeight.w800,
                                          color: _energy == e.key
                                              ? Colors.white
                                              : DS.ink,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Tx(
                                          e.value,
                                          style: DS.text(
                                            size: 11,
                                            weight: FontWeight.w600,
                                            color: _energy == e.key
                                                ? DS.onNavyMuted
                                                : DS.muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (e.key != 5) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Tx(
                            'Craving something sweet?',
                            style: DS.text(size: 15, weight: FontWeight.w700),
                          ),
                        ),
                        DsSwitch(
                          value: _craving,
                          onChanged: (v) => setState(() => _craving = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DsPrimaryButton(
                      label: 'Save energy',
                      height: 54,
                      onPressed: _energy == null ? null : _saveEnergy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Tx(
                'Your patterns',
                style: DS.text(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final i in insights) ...[
                _InsightCard(insight: i),
                const SizedBox(height: 10),
              ],
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Tx('Recent', style: DS.text(size: 17, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final r in recent.take(8)) ...[
                  r.row,
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 16),
              Tx(
                'This is your personal pattern, not a diagnosis. It needs '
                'several days of logging to say anything.',
                textAlign: TextAlign.center,
                style: DS.text(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (insight.kind) {
      InsightKind.dip => (DS.amberTint, DS.amberText, Icons.trending_down),
      InsightKind.good => (DS.greenTint, DS.greenText, Icons.trending_up),
      InsightKind.neutral => (DS.skyTint, DS.navy, Icons.balance_rounded),
      InsightKind.progress => (DS.field, DS.muted, Icons.hourglass_empty),
    };
    return DsCard(
      radius: 24,
      color: bg,
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tx(
                  insight.title,
                  style: DS.text(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: fg,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Tx(
                  insight.detail,
                  style: DS.text(
                    size: 14,
                    weight: FontWeight.w500,
                    color: fg,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.title,
    required this.time,
    required this.onRemove,
  });
  final IconData icon;
  final String title;
  final DateTime time;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final when = sameDay
        ? 'Today ${DateFormat.Hm().format(time)}'
        : DateFormat('d MMM, HH:mm').format(time);
    return DsCard(
      radius: 20,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
      child: Row(
        children: [
          DsIconBadge(icon: icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tx(title, style: DS.text(size: 14.5, weight: FontWeight.w700)),
                Tx(
                  when,
                  style: DS.text(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: L10n.tr('Remove'),
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: DS.iconMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import '../models/checkin.dart';

/// A meal and the energy check that followed it 45 to 180 minutes later.
class MealEnergyPair {
  final MealLog meal;
  final EnergyLog energy;
  const MealEnergyPair(this.meal, this.energy);

  int get minutesAfter => energy.time.difference(meal.time).inMinutes;
}

enum InsightKind { dip, good, neutral, progress }

class Insight {
  final InsightKind kind;
  final String title;
  final String detail;
  const Insight(this.kind, this.title, this.detail);
}

/// Finds a person's own food and energy patterns from their check-ins.
///
/// No model is trained: it matches each meal to the energy check that came
/// about 90 minutes later and compares averages. It only speaks when there
/// are enough pairs, and it says how many it used.
class PatternMiner {
  PatternMiner._();

  static const minMinutes = 45;
  static const maxMinutes = 180;
  static const targetMinutes = 90;

  /// Needed in each group before a comparison is shown.
  static const minPerGroup = 3;

  /// Smallest average difference (on the 1 to 5 scale) worth mentioning.
  static const meaningfulDifference = 0.7;

  /// Each meal takes the unused energy check closest to 90 minutes later.
  static List<MealEnergyPair> pair(
    List<MealLog> meals,
    List<EnergyLog> feelings,
  ) {
    final used = <String>{};
    final sorted = [...meals]..sort((a, b) => a.time.compareTo(b.time));
    final pairs = <MealEnergyPair>[];
    for (final meal in sorted) {
      EnergyLog? best;
      var bestGap = 1 << 30;
      for (final f in feelings) {
        if (used.contains(f.id)) continue;
        final gap = f.time.difference(meal.time).inMinutes;
        if (gap < minMinutes || gap > maxMinutes) continue;
        final distance = (gap - targetMinutes).abs();
        if (distance < bestGap) {
          best = f;
          bestGap = distance;
        }
      }
      if (best != null) {
        used.add(best.id);
        pairs.add(MealEnergyPair(meal, best));
      }
    }
    return pairs;
  }

  static double _mean(Iterable<num> values) =>
      values.fold<double>(0, (a, b) => a + b) / values.length;

  static List<Insight> analyze(List<MealLog> meals, List<EnergyLog> feelings) {
    final pairs = pair(meals, feelings);
    final light = pairs.where((p) => p.meal.carb == CarbLevel.light).toList();
    final heavy = pairs.where((p) => p.meal.carb == CarbLevel.heavy).toList();
    final insights = <Insight>[];

    if (light.length >= minPerGroup && heavy.length >= minPerGroup) {
      final lightEnergy = _mean(light.map((p) => p.energy.energy));
      final heavyEnergy = _mean(heavy.map((p) => p.energy.energy));
      final diff = lightEnergy - heavyEnergy;
      final minutes = _mean(heavy.map((p) => p.minutesAfter)).round();
      final counts =
          '(${heavy.length} sweet or fried meals, '
          '${light.length} light meals)';
      if (diff >= meaningfulDifference) {
        insights.add(
          Insight(
            InsightKind.dip,
            'Your energy drops after sweet or fried meals',
            'About $minutes minutes after them your energy averages '
                '${heavyEnergy.toStringAsFixed(1)} out of 5, against '
                '${lightEnergy.toStringAsFixed(1)} after light meals $counts. '
                'Try a lighter version and a short walk afterwards.',
          ),
        );
      } else if (diff <= -meaningfulDifference) {
        insights.add(
          Insight(
            InsightKind.neutral,
            'No energy dip after sweet or fried meals',
            'Your energy is at least as good after them '
                '(${heavyEnergy.toStringAsFixed(1)} against '
                '${lightEnergy.toStringAsFixed(1)}) $counts. Your blood tests '
                'still matter more than how you feel.',
          ),
        );
      } else {
        insights.add(
          Insight(
            InsightKind.neutral,
            'No clear difference yet',
            'Your energy is similar after light and sweet or fried meals '
                '$counts. Keep logging to see if a pattern appears.',
          ),
        );
      }

      final lightCraving =
          light.where((p) => p.energy.craving).length / light.length;
      final heavyCraving =
          heavy.where((p) => p.energy.craving).length / heavy.length;
      if (heavyCraving - lightCraving >= 0.3) {
        insights.add(
          Insight(
            InsightKind.dip,
            'Sweet or fried meals bring cravings',
            'You wanted something sweet after '
                '${(heavyCraving * 100).round()}% of them, against '
                '${(lightCraving * 100).round()}% after light meals.',
          ),
        );
      }
    }

    // Does one kind of meal stand out as the lowest in energy?
    final byKind = <MealKind, List<MealEnergyPair>>{};
    for (final p in pairs) {
      byKind.putIfAbsent(p.meal.kind, () => []).add(p);
    }
    final comparable = byKind.entries.where(
      (e) => e.value.length >= minPerGroup,
    );
    if (comparable.length >= 2) {
      final ranked = comparable.toList()
        ..sort(
          (a, b) =>
              _mean(a.value.map((p) => p.energy.energy))
                  .compareTo(_mean(b.value.map((p) => p.energy.energy))),
        );
      final lowest = ranked.first;
      final highest = ranked.last;
      final low = _mean(lowest.value.map((p) => p.energy.energy));
      final high = _mean(highest.value.map((p) => p.energy.energy));
      if (high - low >= meaningfulDifference) {
        insights.add(
          Insight(
            InsightKind.dip,
            'Your energy is lowest after ${lowest.key.label.toLowerCase()}',
            'It averages ${low.toStringAsFixed(1)} out of 5, against '
                '${high.toStringAsFixed(1)} after ${highest.key.label.toLowerCase()}.',
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        Insight(
          InsightKind.progress,
          pairs.isEmpty
              ? 'Nothing to compare yet'
              : 'Still learning your pattern',
          'Log a meal, then check your energy about 90 minutes later. '
          'ShifAI needs at least $minPerGroup light and $minPerGroup sweet or '
          'fried meals with an energy check to find a pattern. '
          'So far: ${pairs.length} meal${pairs.length == 1 ? '' : 's'} matched.',
        ),
      );
    }
    return insights;
  }
}

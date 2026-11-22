import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/models/checkin.dart';
import 'package:shifai/services/pattern_miner.dart';

void main() {
  final noon = DateTime(2026, 11, 20, 13, 0);

  MealLog meal(int day, CarbLevel carb, {MealKind kind = MealKind.lunch}) =>
      MealLog(
        id: 'm$day-${carb.name}-${kind.name}',
        time: noon.add(Duration(days: day)),
        kind: kind,
        carb: carb,
      );

  EnergyLog energy(
    int day,
    int minutesAfter,
    int level, {
    bool craving = false,
  }) => EnergyLog(
    id: 'e$day-$minutesAfter-$level',
    time: noon.add(Duration(days: day, minutes: minutesAfter)),
    energy: level,
    craving: craving,
  );

  test('a meal is matched to the energy check closest to 90 minutes later', () {
    final pairs = PatternMiner.pair(
      [meal(0, CarbLevel.heavy)],
      [
        energy(0, 20, 5),
        energy(0, 80, 2),
        energy(0, 170, 4),
        energy(0, 400, 3),
      ],
    );
    expect(pairs, hasLength(1));
    expect(pairs.single.energy.energy, 2);
    expect(pairs.single.minutesAfter, 80);
  });

  test('checks outside 45 to 180 minutes are ignored', () {
    final pairs = PatternMiner.pair(
      [meal(0, CarbLevel.light)],
      [energy(0, 30, 3), energy(0, 240, 3)],
    );
    expect(pairs, isEmpty);
  });

  test('one energy check is never used for two meals', () {
    final a = MealLog(
      id: 'a',
      time: noon,
      kind: MealKind.lunch,
      carb: CarbLevel.light,
    );
    final b = MealLog(
      id: 'b',
      time: noon.add(const Duration(minutes: 30)),
      kind: MealKind.snack,
      carb: CarbLevel.light,
    );
    final pairs = PatternMiner.pair([a, b], [energy(0, 100, 3)]);
    expect(pairs, hasLength(1));
  });

  test('no pairs: says there is nothing to compare yet', () {
    final out = PatternMiner.analyze(const [], const []);
    expect(out.single.kind, InsightKind.progress);
    expect(out.single.title, 'Nothing to compare yet');
  });

  test('too few meals in a group: still learning, no comparison', () {
    final meals = [
      for (var d = 0; d < 2; d++) meal(d, CarbLevel.light),
      for (var d = 2; d < 4; d++) meal(d, CarbLevel.heavy),
    ];
    final feelings = [for (var d = 0; d < 4; d++) energy(d, 90, 3)];
    final out = PatternMiner.analyze(meals, feelings);
    expect(out.single.kind, InsightKind.progress);
    expect(out.single.detail, contains('4 meals matched'));
  });

  test('finds an energy dip after sweet or fried meals', () {
    final meals = [
      for (var d = 0; d < 4; d++) meal(d, CarbLevel.light),
      for (var d = 4; d < 8; d++) meal(d, CarbLevel.heavy),
    ];
    final feelings = [
      for (var d = 0; d < 4; d++) energy(d, 90, 4),
      for (var d = 4; d < 8; d++) energy(d, 90, 2, craving: true),
    ];
    final out = PatternMiner.analyze(meals, feelings);
    final dip = out.firstWhere((i) => i.title.contains('drops after sweet'));
    expect(dip.kind, InsightKind.dip);
    expect(dip.detail, contains('2.0 out of 5'));
    expect(dip.detail, contains('4.0'));
    expect(dip.detail, contains('4 sweet or fried meals, 4 light meals'));
    expect(out.any((i) => i.title.contains('cravings')), isTrue);
  });

  test('says so when there is no difference', () {
    final meals = [
      for (var d = 0; d < 3; d++) meal(d, CarbLevel.light),
      for (var d = 3; d < 6; d++) meal(d, CarbLevel.heavy),
    ];
    final feelings = [for (var d = 0; d < 6; d++) energy(d, 90, 3)];
    final out = PatternMiner.analyze(meals, feelings);
    expect(out.first.title, 'No clear difference yet');
  });

  test('check-ins survive JSON', () {
    final m = meal(1, CarbLevel.regular, kind: MealKind.dinner);
    final back = MealLog.fromJson(m.toJson());
    expect(back.kind, MealKind.dinner);
    expect(back.carb, CarbLevel.regular);
    final e = energy(1, 90, 4, craving: true);
    final eb = EnergyLog.fromJson(e.toJson());
    expect(eb.energy, 4);
    expect(eb.craving, isTrue);
  });
}

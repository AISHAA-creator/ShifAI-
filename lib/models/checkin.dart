/// Quick check-ins: what was eaten, and how energetic the person felt later.
/// Used to find the person's own patterns (see services/pattern_miner.dart).
library;

enum MealKind { breakfast, lunch, dinner, snack }

extension MealKindX on MealKind {
  String get label {
    switch (this) {
      case MealKind.breakfast:
        return 'Breakfast';
      case MealKind.lunch:
        return 'Lunch';
      case MealKind.dinner:
        return 'Dinner';
      case MealKind.snack:
        return 'Snack';
    }
  }
}

/// How much quickly-absorbed carbohydrate a meal had, in simple words.
enum CarbLevel { light, regular, heavy }

extension CarbLevelX on CarbLevel {
  String get label {
    switch (this) {
      case CarbLevel.light:
        return 'Light';
      case CarbLevel.regular:
        return 'Regular';
      case CarbLevel.heavy:
        return 'Sweet or fried';
    }
  }

  String get detail {
    switch (this) {
      case CarbLevel.light:
        return 'Mostly vegetables, legumes, eggs, fish or meat';
      case CarbLevel.regular:
        return 'A normal portion of bread, rice or couscous';
      case CarbLevel.heavy:
        return 'Pastry, sugary drinks, sweet tea, fries or a big plate of bread';
    }
  }
}

class MealLog {
  final String id;
  final DateTime time;
  final MealKind kind;
  final CarbLevel carb;

  const MealLog({
    required this.id,
    required this.time,
    required this.kind,
    required this.carb,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toIso8601String(),
    'kind': kind.name,
    'carb': carb.name,
  };

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
    id: j['id'] as String,
    time: DateTime.parse(j['time'] as String),
    kind: MealKind.values.byName(j['kind'] as String),
    carb: CarbLevel.values.byName(j['carb'] as String),
  );
}

class EnergyLog {
  final String id;
  final DateTime time;

  /// 1 (very low) to 5 (great).
  final int energy;
  final bool craving;

  const EnergyLog({
    required this.id,
    required this.time,
    required this.energy,
    required this.craving,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toIso8601String(),
    'energy': energy,
    'craving': craving,
  };

  factory EnergyLog.fromJson(Map<String, dynamic> j) => EnergyLog(
    id: j['id'] as String,
    time: DateTime.parse(j['time'] as String),
    energy: (j['energy'] as num).toInt(),
    craving: j['craving'] as bool? ?? false,
  );
}

const energyLabels = <int, String>{
  1: 'Very low',
  2: 'Low',
  3: 'OK',
  4: 'Good',
  5: 'Great',
};

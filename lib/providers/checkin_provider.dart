import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/checkin.dart';
import '../services/pattern_miner.dart';

/// Meal and energy check-ins, stored on this device only.
class CheckInProvider extends ChangeNotifier {
  static const _kMeals = 'shifai_meals';
  static const _kFeelings = 'shifai_energy';
  static const _cap = 400;

  List<MealLog> _meals = [];
  List<EnergyLog> _feelings = [];

  CheckInProvider() {
    _load();
  }

  List<MealLog> get meals => List.unmodifiable(_meals);
  List<EnergyLog> get feelings => List.unmodifiable(_feelings);

  List<Insight> get insights => PatternMiner.analyze(_meals, _feelings);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final m = prefs.getString(_kMeals);
      if (m != null) {
        _meals = (jsonDecode(m) as List)
            .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final f = prefs.getString(_kFeelings);
      if (f != null) {
        _feelings = (jsonDecode(f) as List)
            .map((e) => EnergyLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _meals = [];
      _feelings = [];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kMeals,
      jsonEncode(_meals.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kFeelings,
      jsonEncode(_feelings.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addMeal(MealKind kind, CarbLevel carb, {DateTime? time}) async {
    _meals = [
      ..._meals,
      MealLog(
        id: const Uuid().v4(),
        time: time ?? DateTime.now(),
        kind: kind,
        carb: carb,
      ),
    ];
    if (_meals.length > _cap) _meals = _meals.sublist(_meals.length - _cap);
    notifyListeners();
    await _save();
  }

  Future<void> addEnergy(int energy, bool craving, {DateTime? time}) async {
    _feelings = [
      ..._feelings,
      EnergyLog(
        id: const Uuid().v4(),
        time: time ?? DateTime.now(),
        energy: energy.clamp(1, 5),
        craving: craving,
      ),
    ];
    if (_feelings.length > _cap) {
      _feelings = _feelings.sublist(_feelings.length - _cap);
    }
    notifyListeners();
    await _save();
  }

  Future<void> removeMeal(String id) async {
    _meals = _meals.where((e) => e.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> removeEnergy(String id) async {
    _feelings = _feelings.where((e) => e.id != id).toList();
    notifyListeners();
    await _save();
  }
}

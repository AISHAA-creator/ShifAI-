import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minutes of activity the person logged, by day. On this device only.
class ActivityProvider extends ChangeNotifier {
  static const _key = 'shifai_activity';

  Map<String, int> _minutes = {};

  ActivityProvider() {
    _load();
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int minutesOn(DateTime day) => _minutes[_day(day)] ?? 0;

  /// Minutes from Monday to today of the current week.
  int minutesThisWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var total = 0;
    for (var i = 0; i < now.weekday; i++) {
      total += minutesOn(today.subtract(Duration(days: i)));
    }
    return total;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _minutes = (jsonDecode(raw) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
      } catch (_) {
        _minutes = {};
      }
    }
    notifyListeners();
  }

  Future<void> add(int minutes, {DateTime? day}) async {
    final key = _day(day ?? DateTime.now());
    _minutes = {
      ..._minutes,
      key: ((_minutes[key] ?? 0) + minutes).clamp(0, 600),
    };
    notifyListeners();
    await _save();
  }

  /// Removes what was logged today (for a mistaken tap).
  Future<void> clearToday() async {
    _minutes = {..._minutes}..remove(_day(DateTime.now()));
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_minutes));
  }
}

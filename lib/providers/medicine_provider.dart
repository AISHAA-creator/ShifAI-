import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One medicine on the daily schedule.
class Medicine {
  final String id;
  final String name;
  final String dose;
  final String note;
  final String time; // "HH:mm"
  final String? takenOn; // yyyy-MM-dd of the last day it was marked as taken

  const Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.note,
    required this.time,
    this.takenOn,
  });

  bool takenToday(DateTime now) => takenOn == _day(now);

  Medicine copyWith({String? takenOn, bool clearTaken = false}) => Medicine(
    id: id,
    name: name,
    dose: dose,
    note: note,
    time: time,
    takenOn: clearTaken ? null : (takenOn ?? this.takenOn),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'note': note,
    'time': time,
    'takenOn': takenOn,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] as String,
    name: json['name'] as String,
    dose: json['dose'] as String,
    note: json['note'] as String? ?? '',
    time: json['time'] as String,
    takenOn: json['takenOn'] as String?,
  );

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String dayKey(DateTime d) => _day(d);
}

/// Daily medicine schedule, stored on this device only.
///
/// The first three entries are PLACEHOLDERS ("Medicine name") so the screen is
/// not empty. ShifAI never suggests medicines: the doctor decides, and the
/// patient adds or edits entries here.
class MedicineProvider extends ChangeNotifier {
  static const _key = 'shifai_medicines';

  List<Medicine> _items = const [];
  bool _loading = true;

  MedicineProvider() {
    _load();
  }

  List<Medicine> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  int takenCount(DateTime now) => _items.where((m) => m.takenToday(now)).length;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _items = (jsonDecode(raw) as List)
            .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _items = _placeholders;
      }
    } else {
      _items = _placeholders;
    }
    _loading = false;
    notifyListeners();
  }

  static final List<Medicine> _placeholders = [
    Medicine(
      id: 'sample-1',
      name: 'Medicine name',
      dose: '500 mg',
      note: 'with breakfast',
      time: '08:00',
      takenOn: Medicine.dayKey(DateTime.now()),
    ),
    const Medicine(
      id: 'sample-2',
      name: 'Medicine name',
      dose: '500 mg',
      note: 'with lunch',
      time: '13:00',
    ),
    const Medicine(
      id: 'sample-3',
      name: 'Medicine name',
      dose: '500 mg',
      note: 'with dinner',
      time: '20:00',
    ),
  ];

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> add(Medicine medicine) async {
    _items = [..._items, medicine]..sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
    await _save();
  }

  Future<void> markTaken(String id, {bool taken = true}) async {
    _items = [
      for (final m in _items)
        if (m.id == id)
          taken
              ? m.copyWith(takenOn: Medicine.dayKey(DateTime.now()))
              : m.copyWith(clearTaken: true)
        else
          m,
    ];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items = _items.where((m) => m.id != id).toList();
    notifyListeners();
    await _save();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/translator.dart';

/// Text size, chosen city, medicine reminders and which notifications have
/// been seen. Stored on this device only.
class SettingsProvider extends ChangeNotifier {
  static const _kScale = 'shifai_text_scale';
  static const _kCity = 'shifai_city';
  static const _kSeen = 'shifai_seen_notices';
  static const _kReminders = 'shifai_med_reminders';
  static const _kLanguage = 'shifai_language';

  static final textSizes = <double, String>{
    0.9: 'Small',
    1.0: 'Standard',
    1.15: 'Large',
    1.3: 'Extra large',
  };

  double _textScale = 1.0;
  String? _city;
  Set<String> _seen = {};
  bool _medicineReminders = false;
  String _language = 'en';

  SettingsProvider() {
    _load();
  }

  double get textScale => _textScale;
  String get textSizeLabel => textSizes[_textScale] ?? 'Standard';
  String? get city => _city;
  String get language => _language;
  bool get medicineReminders => _medicineReminders;

  bool hasSeen(String id) => _seen.contains(id);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_kScale) ?? 1.0;
    if (!textSizes.containsKey(_textScale)) _textScale = 1.0;
    _city = prefs.getString(_kCity);
    _seen = (prefs.getStringList(_kSeen) ?? const []).toSet();
    _medicineReminders = prefs.getBool(_kReminders) ?? false;
    final lang = prefs.getString(_kLanguage) ?? 'en';
    _language = L10n.supported.contains(lang) ? lang : 'en';
    L10n.code = _language;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kScale, value);
  }

  Future<void> setLanguage(String code) async {
    if (!L10n.supported.contains(code)) return;
    _language = code;
    L10n.code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setCity(String? value) async {
    _city = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kCity);
    } else {
      await prefs.setString(_kCity, value);
    }
  }

  Future<void> setMedicineReminders(bool value) async {
    _medicineReminders = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminders, value);
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final before = _seen.length;
    _seen = {..._seen, ...ids};
    if (_seen.length == before) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // Keep the list from growing forever.
    final keep = _seen.toList();
    await prefs.setStringList(
      _kSeen,
      keep.length > 200 ? keep.sublist(keep.length - 200) : keep,
    );
  }
}

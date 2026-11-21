import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/risk_model.dart';

class ProfileProvider extends ChangeNotifier {
  static const _key = 'shifai_profile';

  UserProfile? _profile;
  RiskModel? _model;
  bool _loading = true;

  UserProfile? get profile => _profile;
  RiskModel? get model => _model;
  bool get loading => _loading;

  RiskAssessment? get assessment {
    final p = _profile;
    final m = _model;
    if (p == null || m == null) return null;
    return m.assess(p);
  }

  /// [model] can be supplied directly (tests); otherwise it is read from assets.
  ProfileProvider({this._model}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    _model ??= await RiskModel.loadAsset();
    _loading = false;
    notifyListeners();
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
    _profile = profile;
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _profile = null;
    notifyListeners();
  }
}

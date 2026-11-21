import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A photo of the neck or armpit kept on this device to compare over time.
/// It is never uploaded and never analysed by a model.
class SkinPhoto {
  final String path;
  final String area; // 'neck' or 'armpit'
  final DateTime date;

  const SkinPhoto({required this.path, required this.area, required this.date});

  Map<String, dynamic> toJson() => {
    'path': path,
    'area': area,
    'date': date.toIso8601String(),
  };

  factory SkinPhoto.fromJson(Map<String, dynamic> j) => SkinPhoto(
    path: j['path'] as String,
    area: j['area'] as String,
    date: DateTime.parse(j['date'] as String),
  );
}

/// Answers of the skin and body check plus the photo timeline.
class SkinCheckProvider extends ChangeNotifier {
  static const _kAnswers = 'shifai_skin_answers';
  static const _kPhotos = 'shifai_skin_photos';

  static const gestational = 'gestational';
  static const family = 'family';
  static const pressure = 'pressure';
  static const active = 'active';
  static const patches = 'patches';
  static const tags = 'tags';

  Map<String, bool> _answers = {};
  List<SkinPhoto> _photos = [];

  SkinCheckProvider() {
    _load();
  }

  bool? answer(String key) => _answers[key];
  List<SkinPhoto> get photos => List.unmodifiable(_photos);

  bool get hasSkinSign => _answers[patches] == true || _answers[tags] == true;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final a = prefs.getString(_kAnswers);
      if (a != null) {
        _answers = (jsonDecode(a) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as bool),
        );
      }
      final p = prefs.getString(_kPhotos);
      if (p != null) {
        _photos = (jsonDecode(p) as List)
            .map((e) => SkinPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _answers = {};
      _photos = [];
    }
    notifyListeners();
  }

  Future<void> setAnswer(String key, bool value) async {
    _answers = {..._answers, key: value};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAnswers, jsonEncode(_answers));
  }

  /// Copies a picked photo into the app's private folder so it survives
  /// cache cleaning. Phones only.
  Future<void> addPhoto(String sourcePath, String area) async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/skin_photos');
    if (!await folder.exists()) await folder.create(recursive: true);
    final now = DateTime.now();
    final target = '${folder.path}/${area}_${now.millisecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(target);
    _photos = [..._photos, SkinPhoto(path: target, area: area, date: now)];
    notifyListeners();
    await _savePhotos();
  }

  Future<void> removePhoto(SkinPhoto photo) async {
    if (!kIsWeb) {
      try {
        await File(photo.path).delete();
      } catch (_) {}
    }
    _photos = _photos.where((p) => p.path != photo.path).toList();
    notifyListeners();
    await _savePhotos();
  }

  Future<void> _savePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPhotos,
      jsonEncode(_photos.map((p) => p.toJson()).toList()),
    );
  }
}

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lab_record.dart';

class LabStorageService {
  static const _legacyKey = 'shifai_lab_records';
  static const _userKeyPrefix = 'shifai_lab_records_user_';
  static const _encryptionKey = 'shifai_lab_cache_encryption_key_v1';

  LabStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher = AesGcm.with256bits();
  Future<SecretKey>? _encryptionKeyFuture;

  Future<List<LabRecord>> loadAll({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final stored = prefs.getString(key);
    if (stored == null || stored.isEmpty) return [];
    final raw = await _decryptOrMigrate(stored, key);
    final list = jsonDecode(raw) as List<dynamic>;
    final records = list
        .map((e) => LabRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<void> saveAll(List<LabRecord> records, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_keyFor(userId), await _encrypt(raw));
  }

  Future<void> add(LabRecord record, {String? userId}) async {
    final records = await loadAll(userId: userId);
    records.removeWhere((existing) => existing.id == record.id);
    records.add(record);
    await saveAll(records, userId: userId);
  }

  String _keyFor(String? userId) =>
      userId == null ? _legacyKey : '$_userKeyPrefix$userId';

  Future<String> _encrypt(String plainText) async {
    final secretBox = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: await _getEncryptionKey(),
    );
    return jsonEncode({
      'version': 1,
      'nonce': base64UrlEncode(secretBox.nonce),
      'cipherText': base64UrlEncode(secretBox.cipherText),
      'mac': base64UrlEncode(secretBox.mac.bytes),
    });
  }

  Future<String> _decryptOrMigrate(String stored, String cacheKey) async {
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      await _writeEncrypted(cacheKey, stored);
      return stored;
    }

    final secretBox = SecretBox(
      base64Url.decode(decoded['cipherText'] as String),
      nonce: base64Url.decode(decoded['nonce'] as String),
      mac: Mac(base64Url.decode(decoded['mac'] as String)),
    );
    final bytes = await _cipher.decrypt(
      secretBox,
      secretKey: await _getEncryptionKey(),
    );
    return utf8.decode(bytes);
  }

  Future<void> _writeEncrypted(String cacheKey, String plainText) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, await _encrypt(plainText));
  }

  Future<SecretKey> _getEncryptionKey() =>
      _encryptionKeyFuture ??= _readOrCreateEncryptionKey();

  Future<SecretKey> _readOrCreateEncryptionKey() async {
    final encoded = await _secureStorage.read(key: _encryptionKey);
    if (encoded != null) {
      return SecretKey(base64Url.decode(encoded));
    }
    final secretKey = await _cipher.newSecretKey();
    await _secureStorage.write(
      key: _encryptionKey,
      value: base64UrlEncode(await secretKey.extractBytes()),
    );
    return secretKey;
  }

  Future<void> delete(String id, {String? userId}) async {
    final records = await loadAll(userId: userId);
    final now = DateTime.now();
    final index = records.indexWhere((record) => record.id == id);
    if (index == -1) return;
    final record = records[index];
    records[index] = LabRecord(
      id: record.id,
      date: record.date,
      fastingGlucoseMgdl: record.fastingGlucoseMgdl,
      fastingInsulinUiuml: record.fastingInsulinUiuml,
      hba1cPercent: record.hba1cPercent,
      triglyceridesMgdl: record.triglyceridesMgdl,
      hdlMgdl: record.hdlMgdl,
      notes: record.notes,
      otherMarkers: record.otherMarkers,
      updatedAt: now,
      deletedAt: now,
    );
    await saveAll(records, userId: userId);
  }
}

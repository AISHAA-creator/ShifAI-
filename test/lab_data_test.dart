import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifai/models/lab_record.dart';
import 'package:shifai/providers/lab_records_provider.dart';
import 'package:shifai/services/lab_cloud_service.dart';
import 'package:shifai/services/lab_storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('HOMA-IR uses normalized values and cloud records round-trip', () {
    final record = LabRecord(
      id: 'a6e5f91a-164c-47e5-bbc3-01c0028edb42',
      date: DateTime(2025, 1, 2),
      fastingGlucoseMgdl: 95,
      fastingInsulinUiuml: 9,
      otherMarkers: const [
        LabMarker(name: 'Cholesterol', value: 195, unit: 'mg/dL'),
      ],
      updatedAt: DateTime.utc(2025, 1, 3),
    );

    expect(record.homaIr, closeTo(95 * 9 / 405, 0.00001));
    final restored = LabRecord.fromCloudJson(record.toCloudJson('user-1'));
    expect(restored.id, record.id);
    expect(restored.homaIr, closeTo(record.homaIr!, 0.00001));
    expect(restored.otherMarkers.single.name, 'Cholesterol');
  });

  test('triglycerides and HDL survive storage and the cloud round trip', () {
    final record = LabRecord(
      id: 'a6e5f91a-164c-47e5-bbc3-01c0028edb43',
      date: DateTime(2026, 10, 12),
      fastingGlucoseMgdl: 83,
      hba1cPercent: 4.5,
      triglyceridesMgdl: 20,
      hdlMgdl: 40,
      updatedAt: DateTime.utc(2026, 10, 13),
    );
    final local = LabRecord.fromJson(record.toJson());
    expect(local.triglyceridesMgdl, 20);
    expect(local.hdlMgdl, 40);
    final cloud = record.toCloudJson('user-1');
    expect(cloud['triglycerides_mg_dl'], 20);
    expect(cloud['hdl_mg_dl'], 40);
    final back = LabRecord.fromCloudJson(cloud);
    expect(back.triglyceridesMgdl, 20);
    expect(back.hdlMgdl, 40);
  });

  test(
    'the new columns are not sent when empty (older databases keep working)',
    () {
      final record = LabRecord(
        id: 'a6e5f91a-164c-47e5-bbc3-01c0028edb44',
        date: DateTime(2026, 10, 12),
        fastingGlucoseMgdl: 90,
        fastingInsulinUiuml: 8,
      );
      final cloud = record.toCloudJson('user-1');
      expect(cloud.containsKey('triglycerides_mg_dl'), isFalse);
      expect(cloud.containsKey('hdl_mg_dl'), isFalse);
    },
  );

  test('sync prefers the newer copy and retains unique offline records', () {
    final old = LabRecord(
      id: 'shared',
      date: DateTime(2025, 1, 1),
      fastingGlucoseMgdl: 90,
      updatedAt: DateTime.utc(2025, 1, 1),
    );
    final newerLocal = LabRecord(
      id: 'shared',
      date: DateTime(2025, 1, 1),
      fastingGlucoseMgdl: 105,
      updatedAt: DateTime.utc(2025, 1, 3),
    );
    final newerRemote = LabRecord(
      id: 'remote-newer',
      date: DateTime(2025, 1, 2),
      fastingGlucoseMgdl: 100,
      updatedAt: DateTime.utc(2025, 1, 4),
    );
    final localOnly = LabRecord(
      id: 'local-only',
      date: DateTime(2025, 1, 3),
      fastingGlucoseMgdl: 98,
      updatedAt: DateTime.utc(2025, 1, 3),
    );
    final remoteOnly = LabRecord(
      id: 'remote-only',
      date: DateTime(2025, 1, 4),
      fastingGlucoseMgdl: 97,
      updatedAt: DateTime.utc(2025, 1, 4),
    );

    final plan = LabSyncPlan.resolve(
      local: [newerLocal, newerRemote, localOnly],
      remote: [old, newerRemote, remoteOnly],
    );

    expect(plan.merged.map((record) => record.id).toSet().length, 4);
    expect(
      plan.merged
          .singleWhere((record) => record.id == 'shared')
          .fastingGlucoseMgdl,
      105,
    );
    expect(
      plan.merged
          .singleWhere((record) => record.id == 'remote-newer')
          .updatedAt,
      newerRemote.updatedAt,
    );
    expect(plan.uploads.map((record) => record.id).toSet(), {
      'shared',
      'local-only',
    });
  });

  test(
    'legacy guest records migrate to encrypted storage and user caches isolate',
    () async {
      const record = {
        'id': 'legacy',
        'date': '2024-06-01T00:00:00.000',
        'fastingGlucoseMgdl': 95.0,
        'fastingInsulinUiuml': 9.0,
        'hba1cPercent': null,
        'notes': null,
      };
      SharedPreferences.setMockInitialValues({
        'shifai_lab_records': jsonEncode([record]),
      });
      final storage = LabStorageService();

      expect((await storage.loadAll()).single.id, 'legacy');
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('shifai_lab_records'),
        isNot(contains('fastingGlucoseMgdl')),
      );

      await storage.add(
        LabRecord(
          id: 'account-a',
          date: DateTime(2025, 1, 1),
          fastingGlucoseMgdl: 100,
        ),
        userId: 'user-a',
      );
      expect((await storage.loadAll(userId: 'user-a')).single.id, 'account-a');
      expect(await storage.loadAll(userId: 'user-b'), isEmpty);
      expect((await storage.loadAll()).single.id, 'legacy');
    },
  );

  test(
    'local result import is explicit, account-scoped, and repeat-safe',
    () async {
      final storage = LabStorageService();
      await storage.add(
        LabRecord(
          id: 'guest-result',
          date: DateTime(2025, 2, 1),
          fastingGlucoseMgdl: 95,
          fastingInsulinUiuml: 9,
        ),
      );
      final provider = LabRecordsProvider(storage: storage);
      provider.setAccount('user-a');

      expect(await provider.importGuestRecordsToAccount(), 1);
      expect(await provider.importGuestRecordsToAccount(), 0);
      expect(provider.records, hasLength(1));
      expect(await storage.loadAll(userId: 'user-b'), isEmpty);
      provider.dispose();
    },
  );
}

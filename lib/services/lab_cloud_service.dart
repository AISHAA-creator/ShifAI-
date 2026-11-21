import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lab_record.dart';

class CloudSyncException implements Exception {
  const CloudSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LabSyncPlan {
  const LabSyncPlan({required this.merged, required this.uploads});

  final List<LabRecord> merged;
  final List<LabRecord> uploads;

  static LabSyncPlan resolve({
    required List<LabRecord> local,
    required List<LabRecord> remote,
  }) {
    final localById = {for (final record in local) record.id: record};
    final remoteById = {for (final record in remote) record.id: record};
    final mergedById = <String, LabRecord>{};
    final uploads = <LabRecord>[];

    for (final record in local) {
      final remoteRecord = remoteById[record.id];
      if (remoteRecord == null ||
          record.updatedAt.isAfter(remoteRecord.updatedAt)) {
        mergedById[record.id] = record;
        uploads.add(record);
      } else {
        mergedById[record.id] = remoteRecord;
      }
    }

    for (final record in remote) {
      if (!localById.containsKey(record.id)) {
        mergedById[record.id] = record;
      }
    }

    final merged = mergedById.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return LabSyncPlan(merged: merged, uploads: uploads);
  }
}

class LabCloudService {
  const LabCloudService(this._client);

  final SupabaseClient _client;

  Future<List<LabRecord>> syncRecords(
    String userId,
    List<LabRecord> localRecords,
  ) async {
    try {
      final response = await _client
          .from('lab_reports')
          .select()
          .eq('user_id', userId);
      final remoteRecords = (response as List<dynamic>)
          .map((row) => LabRecord.fromCloudJson(row as Map<String, dynamic>))
          .toList();
      final plan = LabSyncPlan.resolve(
        local: localRecords,
        remote: remoteRecords,
      );

      if (plan.uploads.isNotEmpty) {
        await _client
            .from('lab_reports')
            .upsert(
              plan.uploads.map((record) => record.toCloudJson(userId)).toList(),
              onConflict: 'id',
            );
      }

      return plan.merged;
    } on ClientException {
      throw const CloudSyncException(
        'Offline. Changes are saved on this device and will sync when reconnected.',
      );
    } on TimeoutException {
      throw const CloudSyncException(
        'Cloud sync timed out. Changes are saved on this device and will retry.',
      );
    } on PostgrestException catch (error) {
      throw CloudSyncException('Cloud sync failed: ${error.message}');
    }
  }
}

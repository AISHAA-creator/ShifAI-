import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesService {
  const UserPreferencesService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> load(String userId) async {
    final rows = await _client
        .from('user_preferences')
        .select('preference_key, value')
        .eq('user_id', userId);
    return {
      for (final row in rows as List<dynamic>)
        (row as Map<String, dynamic>)['preference_key'] as String: row['value'],
    };
  }

  Future<void> save(String userId, String preferenceKey, Object value) async {
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'preference_key': preferenceKey,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,preference_key');
  }
}

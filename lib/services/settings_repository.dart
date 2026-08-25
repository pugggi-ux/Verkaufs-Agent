import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  final SupabaseClient _client;
  SettingsRepository(this._client);

  Future<AppSettings> fetchOrCreate(String userId) async {
    final rows =
        await _client.from('settings').select().eq('user_id', userId).limit(1);
    final list = rows as List;
    if (list.isNotEmpty) {
      return AppSettings.fromMap(list.first as Map<String, dynamic>);
    }
    final row =
        await _client.from('settings').insert({'user_id': userId}).select().single();
    return AppSettings.fromMap(row);
  }

  Future<void> update(AppSettings settings) async {
    await _client
        .from('settings')
        .update(settings.toUpdateMap())
        .eq('user_id', settings.userId);
  }
}

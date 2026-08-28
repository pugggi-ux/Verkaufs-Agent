import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';

class GameRepository {
  final SupabaseClient _client;
  GameRepository(this._client);

  Future<List<Game>> fetchAll(String userId) async {
    final rows = await _client
        .from('games')
        .select()
        .eq('user_id', userId)
        .order('name');
    return (rows as List).map((r) => Game.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String gameId, GameStatus status) async {
    await _client.from('games').update({'status': status.name}).eq('id', gameId);
  }

  /// Setzt denselben Status auf alle Erweiterungen, die zu [baseGameId]
  /// gehören (z.B. wenn ein Basisspiel zum Verkauf vorgemerkt wird, sollen
  /// die eigenen Erweiterungen automatisch mitwandern).
  Future<void> cascadeStatusToExpansions(String baseGameId, GameStatus status) async {
    await _client
        .from('games')
        .update({'status': status.name}).eq('expansion_of_game_id', baseGameId);
  }

  Future<void> updateRecherche(
    String gameId, {
    required double min,
    required double max,
  }) async {
    await _client.from('games').update({
      'recherche_min': min,
      'recherche_max': max,
      'recherche_datum': DateTime.now().toIso8601String(),
    }).eq('id', gameId);
  }

  Future<void> updateAngebotspreis(String gameId, double? angebotspreis) async {
    await _client
        .from('games')
        .update({'angebotspreis': angebotspreis}).eq('id', gameId);
  }

  Future<void> updateZustand(String gameId, String zustand) async {
    await _client.from('games').update({'zustand': zustand}).eq('id', gameId);
  }

  Future<void> updateVerkaufstext(String gameId, String verkaufstext) async {
    await _client
        .from('games')
        .update({'verkaufstext': verkaufstext}).eq('id', gameId);
  }

  Future<void> updateSchmerzgrenzeOverride(String gameId, double? prozent) async {
    await _client
        .from('games')
        .update({'schmerzgrenze_prozent_override': prozent}).eq('id', gameId);
  }

  Future<void> updateKaufpreis(String gameId, double? kaufpreis) async {
    await _client.from('games').update({'kaufpreis': kaufpreis}).eq('id', gameId);
  }
}

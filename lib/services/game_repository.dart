import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';
import 'bgg_service.dart';

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

  /// Importiert/aktualisiert die BGG-Sammlung. Bereits vorhandene Spiele
  /// behalten manuell gepflegte Felder (kaufpreis, kaufdatum), sofern
  /// diese schon gesetzt sind – BGG überschreibt sie nicht.
  Future<int> syncFromBgg(String userId, List<BggCollectionItem> items) async {
    final existingRows = await _client
        .from('games')
        .select('id, bgg_id, kaufpreis, kaufdatum')
        .eq('user_id', userId);
    final existingByBggId = <int, Map<String, dynamic>>{
      for (final row in (existingRows as List))
        (row as Map<String, dynamic>)['bgg_id'] as int: row,
    };

    var importiert = 0;
    for (final item in items) {
      final existing = existingByBggId[item.bggId];
      if (existing == null) {
        await _client.from('games').insert({
          'user_id': userId,
          'bgg_id': item.bggId,
          'name': item.name,
          'cover_image_url': item.imageUrl,
          'kaufpreis': item.pricePaid,
          'kaufdatum': item.acquisitionDate?.toIso8601String().substring(0, 10),
        });
        importiert++;
      } else {
        final update = <String, dynamic>{
          'name': item.name,
          'cover_image_url': item.imageUrl,
        };
        if (existing['kaufpreis'] == null && item.pricePaid != null) {
          update['kaufpreis'] = item.pricePaid;
        }
        if (existing['kaufdatum'] == null && item.acquisitionDate != null) {
          update['kaufdatum'] =
              item.acquisitionDate!.toIso8601String().substring(0, 10);
        }
        await _client.from('games').update(update).eq('id', existing['id'] as String);
      }
    }
    return importiert;
  }

  Future<void> updateStatus(String gameId, GameStatus status) async {
    await _client.from('games').update({'status': status.name}).eq('id', gameId);
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

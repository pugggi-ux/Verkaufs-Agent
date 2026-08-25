import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';
import '../models/game.dart';
import '../models/todo.dart';
import 'todo_generator.dart';

class TodoRepository {
  final SupabaseClient _client;
  TodoRepository(this._client);

  Future<List<GameTodo>> fetchForGame(String gameId) async {
    final rows = await _client
        .from('todos')
        .select()
        .eq('game_id', gameId)
        .order('created_at');
    return (rows as List)
        .map((r) => GameTodo.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setDone(String todoId, bool done) async {
    await _client.from('todos').update({'done': done}).eq('id', todoId);
  }

  /// Gleicht die gespeicherten To-Dos eines Spiels mit den aktuell laut
  /// [TodoGenerator] fälligen ab: fehlende werden angelegt, nicht mehr
  /// relevante (und noch offene) werden entfernt. Bereits erledigte
  /// To-Dos bleiben als Verlauf erhalten.
  Future<List<GameTodo>> syncForGame(Game game, AppSettings settings) async {
    final desired = TodoGenerator.generate(game, settings);
    final desiredKeys = desired.map((d) => d.key).toSet();

    if (desired.isNotEmpty) {
      await _client.from('todos').upsert(
            [
              for (final d in desired)
                {
                  'user_id': game.userId,
                  'game_id': game.id,
                  'key': d.key,
                  'label': d.label,
                }
            ],
            onConflict: 'game_id,key',
            ignoreDuplicates: true,
          );
    }

    final existing = await fetchForGame(game.id);
    final staleIds = existing
        .where((t) => !t.done && !desiredKeys.contains(t.key))
        .map((t) => t.id)
        .toList();
    if (staleIds.isNotEmpty) {
      await _client.from('todos').delete().inFilter('id', staleIds);
    }

    return fetchForGame(game.id);
  }
}

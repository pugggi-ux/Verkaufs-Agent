import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';

class ListingRepository {
  final SupabaseClient _client;
  ListingRepository(this._client);

  Future<Listing?> fetchActiveForGame(String gameId) async {
    final rows = await _client
        .from('listings')
        .select()
        .eq('game_id', gameId)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return Listing.fromMap(list.first as Map<String, dynamic>);
  }

  Future<List<Listing>> fetchAll(String userId) async {
    final rows = await _client
        .from('listings')
        .select()
        .eq('user_id', userId)
        .order('inserat_datum', ascending: false);
    return (rows as List)
        .map((r) => Listing.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> create({
    required String userId,
    required String gameId,
    required DateTime inseratDatum,
  }) async {
    final row = await _client
        .from('listings')
        .insert({
          'user_id': userId,
          'game_id': gameId,
          'inserat_datum': inseratDatum.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return Listing.fromMap(row);
  }

  Future<void> updateStatus(String listingId, ListingStatus status) async {
    await _client
        .from('listings')
        .update({'status': status.name}).eq('id', listingId);
  }
}

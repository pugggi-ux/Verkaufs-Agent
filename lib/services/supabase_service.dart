import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}

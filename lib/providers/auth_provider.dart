import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _errorMessage;
  bool _loading = false;
  StreamSubscription<AuthState>? _sub;

  AuthProvider() {
    _user = SupabaseService.currentUser;
    _sub = SupabaseService.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    return _run(() async {
      await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
    });
  }

  Future<bool> signUp(String email, String password) async {
    return _run(() async {
      await SupabaseService.client.auth.signUp(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

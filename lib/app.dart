import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_data_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/bgg_service.dart';
import 'services/game_repository.dart';
import 'services/listing_repository.dart';
import 'services/settings_repository.dart';
import 'services/supabase_service.dart';
import 'services/todo_repository.dart';

class VerkaufsAgentApp extends StatelessWidget {
  const VerkaufsAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          // AppDataProvider muss OBERHALB des jeweiligen MaterialApp/Navigator
          // sitzen: Routen, die per Navigator.push() geöffnet werden (z.B. der
          // Detail-Screen), sind eigene Geschwister-Subtrees des Navigators,
          // nicht Nachfahren von `home` – ein Provider innerhalb von `home`
          // wäre für sie also nicht auffindbar ("Provider<T> not found").
          if (user == null) {
            return _buildMaterialApp(home: const LoginScreen());
          }

          final client = SupabaseService.client;
          return ChangeNotifierProvider<AppDataProvider>(
            key: ValueKey(user.id),
            create: (_) => AppDataProvider(
              userId: user.id,
              gameRepo: GameRepository(client),
              todoRepo: TodoRepository(client),
              listingRepo: ListingRepository(client),
              settingsRepo: SettingsRepository(client),
              bggService: BggService(client),
            )..loadAll(),
            child: _buildMaterialApp(home: const HomeScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMaterialApp({required Widget home}) {
    return MaterialApp(
      title: 'Verkaufs-Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: home,
    );
  }
}

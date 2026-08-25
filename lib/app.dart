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
      child: MaterialApp(
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
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const LoginScreen();
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
        bggService: BggService(),
      )..loadAll(),
      child: const HomeScreen(),
    );
  }
}

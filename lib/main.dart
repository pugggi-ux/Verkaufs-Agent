import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    runApp(const _KonfigurationsFehlerApp());
    return;
  }

  await SupabaseService.init(url: url, anonKey: anonKey);
  runApp(const VerkaufsAgentApp());
}

class _KonfigurationsFehlerApp extends StatelessWidget {
  const _KonfigurationsFehlerApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'SUPABASE_URL / SUPABASE_ANON_KEY fehlen.\n'
              'Bitte eine .env-Datei (siehe .env.example) im Projektwurzelverzeichnis anlegen.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

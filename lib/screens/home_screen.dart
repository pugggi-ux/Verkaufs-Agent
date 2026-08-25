import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import 'collection_screen.dart';
import 'settings_screen.dart';
import 'swipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _titel = ['Entscheiden', 'Sammlung', 'Einstellungen'];
  static const _screens = [SwipeScreen(), CollectionScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final veraltetAnzahl = provider.rechercheVeraltetListe.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titel[_tab]),
        actions: [
          if (veraltetAnzahl > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Tooltip(
                  message: '$veraltetAnzahl Spiel(e) mit veralteter Recherche',
                  child: Badge(
                    label: Text('$veraltetAnzahl'),
                    child: const Icon(Icons.history_toggle_off),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.games.isEmpty
              ? _FehlerAnsicht(fehler: provider.error!, onRetry: provider.loadAll)
              : IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.swipe), label: 'Entscheiden'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Sammlung'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
    );
  }
}

class _FehlerAnsicht extends StatelessWidget {
  final String fehler;
  final VoidCallback onRetry;
  const _FehlerAnsicht({required this.fehler, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(fehler, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}

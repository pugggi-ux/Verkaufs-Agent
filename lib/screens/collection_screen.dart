import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/app_data_provider.dart';
import 'game_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Zu entscheiden'),
              Tab(text: 'Zum Verkauf'),
              Tab(text: 'Behalten'),
              Tab(text: 'Verkauft'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _GameListe(status: GameStatus.unentschieden),
                _GameListe(status: GameStatus.verkaufen),
                _GameListe(status: GameStatus.behalten),
                _GameListe(status: GameStatus.verkauft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameListe extends StatelessWidget {
  final GameStatus status;
  const _GameListe({required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final games = provider.games.where((g) => g.status == status).toList();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (games.isEmpty) {
      return const Center(child: Text('Keine Spiele in dieser Kategorie.'));
    }

    return RefreshIndicator(
      onRefresh: provider.refreshGames,
      child: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final veraltet =
              game.rechercheVeraltet(provider.settings?.rechercheIntervallTage ?? 90);
          return ListTile(
            leading: SizedBox(
              width: 44,
              height: 44,
              child: game.coverImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(game.coverImageUrl!, fit: BoxFit.cover),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
            ),
            title: Text(game.name),
            subtitle: game.kaufpreis != null
                ? Text('Kaufpreis: ${game.kaufpreis!.toStringAsFixed(2)} €')
                : null,
            trailing: veraltet && status != GameStatus.verkauft
                ? const Tooltip(
                    message: 'Recherche veraltet',
                    child: Icon(Icons.history_toggle_off, color: Colors.orange),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: game.id)),
              );
            },
          );
        },
      ),
    );
  }
}

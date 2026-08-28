import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/app_data_provider.dart';
import '../utils/image_url.dart';
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
    final baseGames = provider.baseGamesByStatus(status);

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (baseGames.isEmpty) {
      return const Center(child: Text('Keine Spiele in dieser Kategorie.'));
    }

    return RefreshIndicator(
      onRefresh: provider.refreshGames,
      child: ListView.builder(
        itemCount: baseGames.length,
        itemBuilder: (context, index) {
          final game = baseGames[index];
          final expansions = provider.expansionsOf(game);
          if (expansions.isEmpty) {
            return _GameZeile(game: game, provider: provider);
          }
          return _BasisspielMitErweiterungen(
            baseGame: game,
            expansions: expansions,
            provider: provider,
          );
        },
      ),
    );
  }
}

class _BasisspielMitErweiterungen extends StatelessWidget {
  final Game baseGame;
  final List<Game> expansions;
  final AppDataProvider provider;

  const _BasisspielMitErweiterungen({
    required this.baseGame,
    required this.expansions,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final kapital = provider.gebundenesKapital(baseGame);
    return ExpansionTile(
      leading: _Cover(url: baseGame.coverImageUrl),
      title: Text(baseGame.name),
      subtitle: Text(
        '${expansions.length} Erweiterung(en) · Gebundenes Kapital: '
        '${kapital.toStringAsFixed(2)} €',
      ),
      children: [
        ListTile(
          dense: true,
          title: const Text('Basisspiel öffnen'),
          leading: const Icon(Icons.open_in_new),
          onTap: () => _oeffnen(context, baseGame),
        ),
        for (final e in expansions)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: _Cover(url: e.coverImageUrl, size: 36),
            title: Text(e.name),
            subtitle: e.kaufpreis != null
                ? Text('Kaufpreis: ${e.kaufpreis!.toStringAsFixed(2)} €')
                : null,
            onTap: () => _oeffnen(context, e),
          ),
      ],
    );
  }

  void _oeffnen(BuildContext context, Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: game.id)),
    );
  }
}

class _GameZeile extends StatelessWidget {
  final Game game;
  final AppDataProvider provider;
  const _GameZeile({required this.game, required this.provider});

  @override
  Widget build(BuildContext context) {
    final veraltet =
        game.rechercheVeraltet(provider.settings?.rechercheIntervallTage ?? 90);
    return ListTile(
      leading: _Cover(url: game.coverImageUrl),
      title: Text(game.name),
      subtitle: game.kaufpreis != null
          ? Text('Kaufpreis: ${game.kaufpreis!.toStringAsFixed(2)} €')
          : null,
      trailing: veraltet && game.status != GameStatus.verkauft
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
  }
}

class _Cover extends StatelessWidget {
  final String? url;
  final double size;
  const _Cover({required this.url, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: url != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(corsProxiedImageUrl(url)!, fit: BoxFit.cover),
            )
          : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
    );
  }
}

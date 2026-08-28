import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/app_data_provider.dart';
import '../utils/image_url.dart';
import '../widgets/swipe_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  late List<Game> _queue;
  int _index = 0;
  int _behalten = 0;
  int _verkaufen = 0;
  int _spaeter = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.of(context.read<AppDataProvider>().zumEntscheiden);
  }

  void _neueSession() {
    setState(() {
      _queue = List.of(context.read<AppDataProvider>().zumEntscheiden);
      _index = 0;
      _behalten = 0;
      _verkaufen = 0;
      _spaeter = 0;
    });
  }

  void _onDecided(Game game, SwipeDecision decision) {
    final provider = context.read<AppDataProvider>();
    switch (decision) {
      case SwipeDecision.behalten:
        _behalten++;
        provider.decide(game, GameStatus.behalten);
        break;
      case SwipeDecision.verkaufen:
        _verkaufen++;
        provider.decide(game, GameStatus.verkaufen);
        break;
      case SwipeDecision.spaeter:
        _spaeter++;
        break;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return _EmptyState(onRefresh: _neueSession);
    }
    if (_index >= _queue.length) {
      return _SummaryState(
        behalten: _behalten,
        verkaufen: _verkaufen,
        spaeter: _spaeter,
        onNeueSession: _neueSession,
      );
    }

    final game = _queue[_index];
    final naechstes = _index + 1 < _queue.length ? _queue[_index + 1] : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('${_index + 1} / ${_queue.length}',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (naechstes != null)
                  Transform.scale(
                    scale: 0.94,
                    child: Opacity(
                      opacity: 0.6,
                      child: _StaticCardPreview(game: naechstes),
                    ),
                  ),
                SwipeCard(
                  key: ValueKey(game.id),
                  game: game,
                  onDecided: (d) => _onDecided(game, d),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AktionsButton(
                icon: Icons.sell_outlined,
                farbe: Colors.red,
                label: 'Verkaufen',
                onTap: () => _onDecided(game, SwipeDecision.verkaufen),
              ),
              _AktionsButton(
                icon: Icons.schedule,
                farbe: Colors.orange,
                label: 'Später',
                onTap: () => _onDecided(game, SwipeDecision.spaeter),
              ),
              _AktionsButton(
                icon: Icons.favorite_outline,
                farbe: Colors.green,
                label: 'Behalten',
                onTap: () => _onDecided(game, SwipeDecision.behalten),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AktionsButton extends StatelessWidget {
  final IconData icon;
  final Color farbe;
  final String label;
  final VoidCallback onTap;

  const _AktionsButton({
    required this.icon,
    required this.farbe,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon, color: farbe),
          iconSize: 28,
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _StaticCardPreview extends StatelessWidget {
  final Game game;
  const _StaticCardPreview({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox.expand(
        child: game.coverImageUrl != null
            ? Image.network(corsProxiedImageUrl(game.coverImageUrl)!, fit: BoxFit.cover)
            : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Keine unentschiedenen Spiele mehr.\nAlle Spiele wurden bereits einsortiert.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRefresh, child: const Text('Aktualisieren')),
          ],
        ),
      ),
    );
  }
}

class _SummaryState extends StatelessWidget {
  final int behalten;
  final int verkaufen;
  final int spaeter;
  final VoidCallback onNeueSession;

  const _SummaryState({
    required this.behalten,
    required this.verkaufen,
    required this.spaeter,
    required this.onNeueSession,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Session abgeschlossen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _ZeileErgebnis(label: 'Behalten', anzahl: behalten, icon: Icons.favorite, farbe: Colors.green),
            _ZeileErgebnis(label: 'Verkaufen', anzahl: verkaufen, icon: Icons.sell, farbe: Colors.red),
            _ZeileErgebnis(label: 'Später entschieden', anzahl: spaeter, icon: Icons.schedule, farbe: Colors.orange),
            const SizedBox(height: 24),
            FilledButton(onPressed: onNeueSession, child: const Text('Neue Session starten')),
          ],
        ),
      ),
    );
  }
}

class _ZeileErgebnis extends StatelessWidget {
  final String label;
  final int anzahl;
  final IconData icon;
  final Color farbe;

  const _ZeileErgebnis({
    required this.label,
    required this.anzahl,
    required this.icon,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: farbe),
          const SizedBox(width: 8),
          Text('$label: $anzahl'),
        ],
      ),
    );
  }
}

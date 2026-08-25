import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/listing.dart';
import '../models/todo.dart';
import '../providers/app_data_provider.dart';
import '../services/sales_text_generator.dart';
import '../widgets/price_range_bar.dart';
import '../widgets/todo_checklist.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final _kaufpreisCtrl = TextEditingController();
  final _rechercheMinCtrl = TextEditingController();
  final _rechercheMaxCtrl = TextEditingController();
  final _angebotspreisCtrl = TextEditingController();
  final _zustandCtrl = TextEditingController();
  final _schmerzgrenzeOverrideCtrl = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  List<GameTodo> _todos = [];
  Listing? _listing;
  bool _ladeDetails = true;

  @override
  void initState() {
    super.initState();
    _initFromGame(_findGame());
    _ladeZusatzdaten();
  }

  Game? _findGame() {
    final provider = context.read<AppDataProvider>();
    try {
      return provider.games.firstWhere((g) => g.id == widget.gameId);
    } catch (_) {
      return null;
    }
  }

  void _initFromGame(Game? game) {
    if (game == null) return;
    _kaufpreisCtrl.text = game.kaufpreis?.toStringAsFixed(2) ?? '';
    _rechercheMinCtrl.text = game.rechercheMin?.toStringAsFixed(2) ?? '';
    _rechercheMaxCtrl.text = game.rechercheMax?.toStringAsFixed(2) ?? '';
    _angebotspreisCtrl.text = game.angebotspreis?.toStringAsFixed(2) ?? '';
    _zustandCtrl.text = game.zustand ?? '';
    _schmerzgrenzeOverrideCtrl.text =
        game.schmerzgrenzeProzentOverride?.toStringAsFixed(0) ?? '';
  }

  Future<void> _ladeZusatzdaten() async {
    final provider = context.read<AppDataProvider>();
    final game = _findGame();
    if (game == null) return;
    final results = await Future.wait([
      provider.loadTodos(game),
      provider.loadListing(game.id),
    ]);
    if (!mounted) return;
    setState(() {
      _todos = results[0] as List<GameTodo>;
      _listing = results[1] as Listing?;
      _ladeDetails = false;
    });
  }

  Future<void> _reloadTodos() async {
    final provider = context.read<AppDataProvider>();
    final game = _findGame();
    if (game == null) return;
    final todos = await provider.loadTodos(game);
    if (!mounted) return;
    setState(() => _todos = todos);
  }

  @override
  void dispose() {
    _kaufpreisCtrl.dispose();
    _rechercheMinCtrl.dispose();
    _rechercheMaxCtrl.dispose();
    _angebotspreisCtrl.dispose();
    _zustandCtrl.dispose();
    _schmerzgrenzeOverrideCtrl.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final game = provider.games.where((g) => g.id == widget.gameId).firstOrNull;

    if (game == null) {
      return const Scaffold(body: Center(child: Text('Spiel nicht gefunden.')));
    }

    final settings = provider.settings;
    final schmerzgrenze =
        settings != null ? game.schmerzgrenzeWert(settings.schmerzgrenzeProzentDefault) : null;
    final veraltet =
        game.rechercheVeraltet(settings?.rechercheIntervallTage ?? 90);

    return Scaffold(
      appBar: AppBar(title: Text(game.name)),
      body: _ladeDetails
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    if (game.coverImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(game.coverImageUrl!,
                            width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusAuswahl(
                        status: game.status,
                        onChanged: (s) => provider.decide(game, s).then((_) => _reloadTodos()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Abschnitt(
                  titel: 'Kaufpreis & Kaufdatum',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kaufpreisCtrl,
                          decoration: const InputDecoration(labelText: 'Kaufpreis (€)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onSubmitted: (v) => provider.updateKaufpreis(game.id, _parse(v)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(game.kaufdatum != null
                          ? 'Kauf: ${_dateFormat.format(game.kaufdatum!)}'
                          : 'Kaufdatum unbekannt'),
                    ],
                  ),
                ),
                _Abschnitt(
                  titel: 'Marktwert-Einschätzung',
                  trailing: veraltet
                      ? const Chip(
                          label: Text('Recherche veraltet'),
                          backgroundColor: Color(0xFFFFE0B2),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rechercheMinCtrl,
                              decoration: const InputDecoration(labelText: 'Min (€)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _rechercheMaxCtrl,
                              decoration: const InputDecoration(labelText: 'Max (€)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final min = _parse(_rechercheMinCtrl.text);
                              final max = _parse(_rechercheMaxCtrl.text);
                              if (min == null || max == null) return;
                              provider
                                  .updateRecherche(game.id, min: min, max: max)
                                  .then((_) => _reloadTodos());
                            },
                            child: const Text('Speichern'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _schmerzgrenzeOverrideCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Schmerzgrenze % (Override, optional)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: (v) =>
                            provider.updateSchmerzgrenzeOverride(game.id, _parse(v)),
                      ),
                      if (game.hatRecherche) ...[
                        const SizedBox(height: 12),
                        PriceRangeBar(
                          min: game.rechercheMin!,
                          max: game.rechercheMax!,
                          schmerzgrenze: schmerzgrenze,
                          angebotspreis: game.angebotspreis,
                        ),
                      ],
                      if (game.rechercheDatum != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Letzte Recherche: ${_dateFormat.format(game.rechercheDatum!)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (game.status == GameStatus.verkaufen) ...[
                  _Abschnitt(
                    titel: 'Angebotspreis & Zustand',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _angebotspreisCtrl,
                          decoration: const InputDecoration(labelText: 'Angebotspreis (€)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onSubmitted: (v) => provider
                              .updateAngebotspreis(game.id, _parse(v))
                              .then((_) => _reloadTodos()),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _zustandCtrl,
                          decoration: const InputDecoration(labelText: 'Zustand'),
                          maxLines: 2,
                          onSubmitted: (v) => provider
                              .updateZustand(game.id, v)
                              .then((_) => _reloadTodos()),
                        ),
                      ],
                    ),
                  ),
                  _Abschnitt(
                    titel: 'To-Dos',
                    child: TodoChecklist(
                      todos: _todos,
                      onToggle: (t) => provider.toggleTodo(t).then((_) => _reloadTodos()),
                    ),
                  ),
                  _Abschnitt(
                    titel: 'Verkaufstext',
                    child: _VerkaufstextBlock(game: game),
                  ),
                  _Abschnitt(
                    titel: 'Inserat-Tracking',
                    child: _InseratTracking(
                      game: game,
                      listing: _listing,
                      onListingChanged: (l) => setState(() => _listing = l),
                    ),
                  ),
                ] else if (_todos.isNotEmpty)
                  _Abschnitt(titel: 'Hinweise', child: TodoChecklist(
                    todos: _todos,
                    onToggle: (t) => provider.toggleTodo(t).then((_) => _reloadTodos()),
                  )),
              ],
            ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String titel;
  final Widget child;
  final Widget? trailing;

  const _Abschnitt({required this.titel, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(titel, style: Theme.of(context).textTheme.titleMedium)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusAuswahl extends StatelessWidget {
  final GameStatus status;
  final void Function(GameStatus) onChanged;
  const _StatusAuswahl({required this.status, required this.onChanged});

  static const _labels = {
    GameStatus.unentschieden: 'Unentschieden',
    GameStatus.behalten: 'Behalten',
    GameStatus.verkaufen: 'Zum Verkauf',
    GameStatus.verkauft: 'Verkauft',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GameStatus>(
      initialValue: status,
      decoration: const InputDecoration(labelText: 'Status'),
      items: [
        for (final s in GameStatus.values)
          DropdownMenuItem(value: s, child: Text(_labels[s]!)),
      ],
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}

class _VerkaufstextBlock extends StatefulWidget {
  final Game game;
  const _VerkaufstextBlock({required this.game});

  @override
  State<_VerkaufstextBlock> createState() => _VerkaufstextBlockState();
}

class _VerkaufstextBlockState extends State<_VerkaufstextBlock> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.game.verkaufstext ?? '');
  }

  @override
  void didUpdateWidget(covariant _VerkaufstextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppDataProvider>();
    final settings = provider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: settings == null
                    ? null
                    : () {
                        final generiert = SalesTextGenerator.generate(widget.game, settings);
                        setState(() => _ctrl.text = generiert);
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Text generieren'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => provider.updateVerkaufstext(widget.game.id, v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => provider.updateVerkaufstext(widget.game.id, _ctrl.text),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Speichern'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _ctrl.text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('In Zwischenablage kopiert.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Kopieren'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InseratTracking extends StatelessWidget {
  final Game game;
  final Listing? listing;
  final void Function(Listing) onListingChanged;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  _InseratTracking({
    required this.game,
    required this.listing,
    required this.onListingChanged,
  });

  static const _statusLabels = {
    ListingStatus.online: 'Online',
    ListingStatus.reserviert: 'Reserviert',
    ListingStatus.verkauft: 'Verkauft',
    ListingStatus.versendet: 'Versendet',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppDataProvider>();

    if (listing == null) {
      return FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Inserat eingestellt – Datum eintragen'),
        onPressed: () async {
          final datum = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 1)),
          );
          if (datum == null) return;
          await provider.createListing(game, datum);
          final neu = provider.listingByGame[game.id];
          if (neu != null) onListingChanged(neu);
        },
      );
    }

    final l = listing!;
    final tageBisAblauf = l.ablaufdatum.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eingestellt am: ${_dateFormat.format(l.inseratDatum)}'),
        Text('Läuft ab am: ${_dateFormat.format(l.ablaufdatum)}'),
        if (l.status == ListingStatus.online)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tageBisAblauf < 0
                  ? 'Inserat-Laufzeit abgelaufen – ggf. verlängern.'
                  : 'Noch $tageBisAblauf Tage bis Ablauf.',
              style: TextStyle(
                color: tageBisAblauf <= 8
                    ? Theme.of(context).colorScheme.error
                    : null,
                fontWeight: tageBisAblauf <= 8 ? FontWeight.bold : null,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in ListingStatus.values)
              ChoiceChip(
                label: Text(_statusLabels[s]!),
                selected: l.status == s,
                onSelected: (_) async {
                  await provider.updateListingStatus(l, s);
                  final neu = provider.listingByGame[game.id];
                  if (neu != null) onListingChanged(neu);
                },
              ),
          ],
        ),
      ],
    );
  }
}

extension _FirstOrNullGame on Iterable<Game> {
  Game? get firstOrNull => isEmpty ? null : first;
}

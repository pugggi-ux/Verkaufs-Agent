import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _bggUsernameCtrl = TextEditingController();
  final _schmerzgrenzeCtrl = TextEditingController();
  final _intervallCtrl = TextEditingController();
  final _erinnerungCtrl = TextEditingController();
  final _vorlageCtrl = TextEditingController();
  final _zahlungCtrl = TextEditingController();
  final _versandCtrl = TextEditingController();
  final _gewaehrleistungCtrl = TextEditingController();

  bool _initialisiert = false;

  void _initFromSettings(AppDataProvider provider) {
    if (_initialisiert || provider.settings == null) return;
    final s = provider.settings!;
    _bggUsernameCtrl.text = s.bggUsername ?? '';
    _schmerzgrenzeCtrl.text = s.schmerzgrenzeProzentDefault.toStringAsFixed(0);
    _intervallCtrl.text = s.rechercheIntervallTage.toString();
    _erinnerungCtrl.text = s.erinnerungTageVorAblauf.toString();
    _vorlageCtrl.text = s.verkaufstextVorlage;
    _zahlungCtrl.text = s.zahlungsmethoden;
    _versandCtrl.text = s.versandmodalitaeten;
    _gewaehrleistungCtrl.text = s.gewaehrleistungsausschluss;
    _initialisiert = true;
  }

  @override
  void dispose() {
    _bggUsernameCtrl.dispose();
    _schmerzgrenzeCtrl.dispose();
    _intervallCtrl.dispose();
    _erinnerungCtrl.dispose();
    _vorlageCtrl.dispose();
    _zahlungCtrl.dispose();
    _versandCtrl.dispose();
    _gewaehrleistungCtrl.dispose();
    super.dispose();
  }

  Future<void> _speichern(AppDataProvider provider) async {
    final s = provider.settings;
    if (s == null) return;
    await provider.updateSettings(s.copyWith(
      bggUsername: _bggUsernameCtrl.text.trim(),
      schmerzgrenzeProzentDefault:
          double.tryParse(_schmerzgrenzeCtrl.text.replaceAll(',', '.')) ??
              s.schmerzgrenzeProzentDefault,
      rechercheIntervallTage: int.tryParse(_intervallCtrl.text) ?? s.rechercheIntervallTage,
      erinnerungTageVorAblauf:
          int.tryParse(_erinnerungCtrl.text) ?? s.erinnerungTageVorAblauf,
      verkaufstextVorlage: _vorlageCtrl.text,
      zahlungsmethoden: _zahlungCtrl.text,
      versandmodalitaeten: _versandCtrl.text,
      gewaehrleistungsausschluss: _gewaehrleistungCtrl.text,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Einstellungen gespeichert.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    _initFromSettings(provider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('BGG-Sync', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _bggUsernameCtrl,
          decoration: const InputDecoration(labelText: 'BoardGameGeek-Benutzername'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: provider.syncingBgg
              ? null
              : () async {
                  await _speichern(provider);
                  final ok = await provider.syncBgg();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? (provider.bggSyncMessage ?? 'Sync abgeschlossen.')
                          : (provider.error ?? 'Sync fehlgeschlagen.')),
                    ),
                  );
                },
          icon: provider.syncingBgg
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync),
          label: const Text('Sammlung jetzt synchronisieren'),
        ),
        const Divider(height: 32),
        Text('Marktwert-Einschätzung', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _schmerzgrenzeCtrl,
          decoration: const InputDecoration(
              labelText: 'Schmerzgrenze % vom Kaufpreis (Standard)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _intervallCtrl,
          decoration:
              const InputDecoration(labelText: 'Recherche-Intervall (Tage, z.B. 90)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _erinnerungCtrl,
          decoration: const InputDecoration(
              labelText: 'Erinnerung vor Inserat-Ablauf (Tage, z.B. 8)'),
          keyboardType: TextInputType.number,
        ),
        const Divider(height: 32),
        Text('Verkaufstext-Bausteine', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Platzhalter: {spielname}, {zustand}, {angebotspreis}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _vorlageCtrl,
          decoration: const InputDecoration(labelText: 'Vorlage', border: OutlineInputBorder()),
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _zahlungCtrl,
          decoration:
              const InputDecoration(labelText: 'Zahlungsmethoden', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _versandCtrl,
          decoration: const InputDecoration(
              labelText: 'Versandmodalitäten', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gewaehrleistungCtrl,
          decoration: const InputDecoration(
              labelText: 'Gewährleistungsausschluss', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _speichern(provider),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Einstellungen speichern'),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthProvider>().signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Abmelden'),
        ),
      ],
    );
  }
}

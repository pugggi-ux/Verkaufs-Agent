import '../models/app_settings.dart';
import '../models/game.dart';

class TodoDraft {
  final String key;
  final String label;
  const TodoDraft(this.key, this.label);
}

/// Erzeugt die pro Spiel fällige To-Do-Liste, wie in SPEC v1 (Kernfunktion 3)
/// beschrieben.
class TodoGenerator {
  static List<TodoDraft> generate(Game game, AppSettings settings) {
    final drafts = <TodoDraft>[];

    if (game.status == GameStatus.verkaufen) {
      if (!game.hatRecherche || game.rechercheVeraltet(settings.rechercheIntervallTage)) {
        drafts.add(const TodoDraft('recherche', 'Marktrecherche durchführen/aktualisieren'));
      }
      if (game.angebotspreis == null) {
        drafts.add(const TodoDraft('preis', 'Angebotspreis festlegen'));
      }
      drafts.add(const TodoDraft('foto', 'Foto von der Spieleschachtel machen'));
      if (game.zustand == null || game.zustand!.trim().isEmpty) {
        drafts.add(const TodoDraft('zustand', 'Zustand beschreiben'));
      }
      drafts.add(const TodoDraft('text', 'Verkaufstext generieren/prüfen'));
      drafts.add(const TodoDraft(
        'inserieren',
        'Inserat auf Kleinanzeigen einstellen → Datum eintragen',
      ));
    } else {
      // "Markt sondieren" gilt unabhängig vom Verkaufsstatus für beobachtete,
      // aber (noch) nicht zum Verkauf vorgemerkte Spiele.
      if (game.rechercheVeraltet(settings.rechercheIntervallTage)) {
        drafts.add(const TodoDraft('markt_sondieren', 'Markt sondieren'));
      }
    }

    return drafts;
  }
}

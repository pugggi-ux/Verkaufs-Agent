import '../models/app_settings.dart';
import '../models/game.dart';

class SalesTextGenerator {
  static String generate(Game game, AppSettings settings) {
    final zustand =
        (game.zustand != null && game.zustand!.trim().isNotEmpty) ? game.zustand! : '-';
    final preis = game.angebotspreis != null
        ? '${game.angebotspreis!.toStringAsFixed(2)} €'
        : '-';

    final kopf = settings.verkaufstextVorlage
        .replaceAll('{spielname}', game.name)
        .replaceAll('{zustand}', zustand)
        .replaceAll('{angebotspreis}', preis);

    return [
      kopf,
      '',
      settings.zahlungsmethoden,
      settings.versandmodalitaeten,
      settings.gewaehrleistungsausschluss,
    ].join('\n');
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class BggSyncResult {
  final int neu;
  final int gesamt;
  final int basisspiele;
  final int erweiterungen;
  final int erweiterungenVerknuepft;
  final bool privateInfoVerfuegbar;

  const BggSyncResult({
    required this.neu,
    required this.gesamt,
    required this.basisspiele,
    required this.erweiterungen,
    required this.erweiterungenVerknuepft,
    required this.privateInfoVerfuegbar,
  });

  factory BggSyncResult.fromMap(Map<String, dynamic> map) {
    return BggSyncResult(
      neu: map['neu'] as int? ?? 0,
      gesamt: map['gesamt'] as int? ?? 0,
      basisspiele: map['basisspiele'] as int? ?? 0,
      erweiterungen: map['erweiterungen'] as int? ?? 0,
      erweiterungenVerknuepft: map['erweiterungenVerknuepft'] as int? ?? 0,
      privateInfoVerfuegbar: map['privateInfoVerfuegbar'] as bool? ?? false,
    );
  }

  String get zusammenfassung {
    final basis = '$neu neue Spiele importiert, $gesamt insgesamt abgeglichen '
        '($basisspiele Basisspiele, $erweiterungen Erweiterungen).';
    return privateInfoVerfuegbar
        ? basis
        : '$basis Hinweis: Kaufpreise (pricepaid) konnten nicht abgerufen werden – '
            'BGG-Login fehlgeschlagen oder kein Passwort hinterlegt.';
  }
}

/// Ruft die serverseitige Supabase-Edge-Function `bgg-sync` auf, die den
/// eigentlichen BGG-Collection-Abgleich (inkl. Login für private Felder wie
/// `pricepaid`) durchführt. Läuft bewusst nicht im Client, weil BGG dafür
/// einen Bearer-Token sowie – für `pricepaid` – eine Login-Session-Cookie
/// verlangt, die aus einer Browser-App heraus (CORS) ohnehin nicht gesetzt
/// werden könnte.
class BggService {
  final SupabaseClient client;
  BggService(this.client);

  Future<BggSyncResult> syncCollection() async {
    final response = await client.functions.invoke('bgg-sync');
    final data = response.data;
    if (response.status != 200 || data is! Map) {
      final message = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'BGG-Sync fehlgeschlagen (HTTP ${response.status}).';
      throw BggSyncException(message);
    }
    return BggSyncResult.fromMap(Map<String, dynamic>.from(data));
  }
}

class BggSyncException implements Exception {
  final String message;
  const BggSyncException(this.message);

  @override
  String toString() => message;
}

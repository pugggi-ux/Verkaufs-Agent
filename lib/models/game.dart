enum GameStatus { unentschieden, behalten, verkaufen, verkauft }

GameStatus gameStatusFromString(String value) {
  return GameStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => GameStatus.unentschieden,
  );
}

class Game {
  final String id;
  final String userId;
  final int bggId;
  final String name;
  final String? coverImageUrl;
  final double? kaufpreis;
  final DateTime? kaufdatum;
  final GameStatus status;
  final double? rechercheMin;
  final double? rechercheMax;
  final DateTime? rechercheDatum;
  final double? schmerzgrenzeProzentOverride;
  final double? angebotspreis;
  final String? zustand;
  final String? verkaufstext;
  final String subtype;
  final String? expansionOfGameId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Game({
    required this.id,
    required this.userId,
    required this.bggId,
    required this.name,
    this.coverImageUrl,
    this.kaufpreis,
    this.kaufdatum,
    this.status = GameStatus.unentschieden,
    this.rechercheMin,
    this.rechercheMax,
    this.rechercheDatum,
    this.schmerzgrenzeProzentOverride,
    this.angebotspreis,
    this.zustand,
    this.verkaufstext,
    this.subtype = 'boardgame',
    this.expansionOfGameId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpansion => subtype == 'boardgameexpansion';

  bool get hatRecherche => rechercheMin != null && rechercheMax != null;

  bool rechercheVeraltet(int intervallTage) {
    if (rechercheDatum == null) return true;
    final alterInTagen = DateTime.now().difference(rechercheDatum!).inDays;
    return alterInTagen > intervallTage;
  }

  double? schmerzgrenzeWert(double globalerProzentDefault) {
    if (kaufpreis == null) return null;
    final prozent = schmerzgrenzeProzentOverride ?? globalerProzentDefault;
    return kaufpreis! * (prozent / 100);
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      bggId: map['bgg_id'] as int,
      name: map['name'] as String,
      coverImageUrl: map['cover_image_url'] as String?,
      kaufpreis: (map['kaufpreis'] as num?)?.toDouble(),
      kaufdatum:
          map['kaufdatum'] != null ? DateTime.parse(map['kaufdatum'] as String) : null,
      status: gameStatusFromString(map['status'] as String? ?? 'unentschieden'),
      rechercheMin: (map['recherche_min'] as num?)?.toDouble(),
      rechercheMax: (map['recherche_max'] as num?)?.toDouble(),
      rechercheDatum: map['recherche_datum'] != null
          ? DateTime.parse(map['recherche_datum'] as String)
          : null,
      schmerzgrenzeProzentOverride:
          (map['schmerzgrenze_prozent_override'] as num?)?.toDouble(),
      angebotspreis: (map['angebotspreis'] as num?)?.toDouble(),
      zustand: map['zustand'] as String?,
      verkaufstext: map['verkaufstext'] as String?,
      subtype: map['subtype'] as String? ?? 'boardgame',
      expansionOfGameId: map['expansion_of_game_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

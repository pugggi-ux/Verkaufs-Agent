class AppSettings {
  final String userId;
  final double schmerzgrenzeProzentDefault;
  final int rechercheIntervallTage;
  final int erinnerungTageVorAblauf;
  final String? bggUsername;
  final String verkaufstextVorlage;
  final String zahlungsmethoden;
  final String versandmodalitaeten;
  final String gewaehrleistungsausschluss;

  const AppSettings({
    required this.userId,
    required this.schmerzgrenzeProzentDefault,
    required this.rechercheIntervallTage,
    required this.erinnerungTageVorAblauf,
    this.bggUsername,
    required this.verkaufstextVorlage,
    required this.zahlungsmethoden,
    required this.versandmodalitaeten,
    required this.gewaehrleistungsausschluss,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      userId: map['user_id'] as String,
      schmerzgrenzeProzentDefault:
          (map['schmerzgrenze_prozent_default'] as num?)?.toDouble() ?? 65,
      rechercheIntervallTage: map['recherche_intervall_tage'] as int? ?? 90,
      erinnerungTageVorAblauf: map['erinnerung_tage_vor_ablauf'] as int? ?? 8,
      bggUsername: map['bgg_username'] as String?,
      verkaufstextVorlage: map['verkaufstext_vorlage'] as String? ?? '',
      zahlungsmethoden: map['zahlungsmethoden'] as String? ?? '',
      versandmodalitaeten: map['versandmodalitaeten'] as String? ?? '',
      gewaehrleistungsausschluss: map['gewaehrleistungsausschluss'] as String? ?? '',
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'schmerzgrenze_prozent_default': schmerzgrenzeProzentDefault,
      'recherche_intervall_tage': rechercheIntervallTage,
      'erinnerung_tage_vor_ablauf': erinnerungTageVorAblauf,
      'bgg_username': bggUsername,
      'verkaufstext_vorlage': verkaufstextVorlage,
      'zahlungsmethoden': zahlungsmethoden,
      'versandmodalitaeten': versandmodalitaeten,
      'gewaehrleistungsausschluss': gewaehrleistungsausschluss,
    };
  }

  AppSettings copyWith({
    double? schmerzgrenzeProzentDefault,
    int? rechercheIntervallTage,
    int? erinnerungTageVorAblauf,
    String? bggUsername,
    String? verkaufstextVorlage,
    String? zahlungsmethoden,
    String? versandmodalitaeten,
    String? gewaehrleistungsausschluss,
  }) {
    return AppSettings(
      userId: userId,
      schmerzgrenzeProzentDefault:
          schmerzgrenzeProzentDefault ?? this.schmerzgrenzeProzentDefault,
      rechercheIntervallTage: rechercheIntervallTage ?? this.rechercheIntervallTage,
      erinnerungTageVorAblauf:
          erinnerungTageVorAblauf ?? this.erinnerungTageVorAblauf,
      bggUsername: bggUsername ?? this.bggUsername,
      verkaufstextVorlage: verkaufstextVorlage ?? this.verkaufstextVorlage,
      zahlungsmethoden: zahlungsmethoden ?? this.zahlungsmethoden,
      versandmodalitaeten: versandmodalitaeten ?? this.versandmodalitaeten,
      gewaehrleistungsausschluss:
          gewaehrleistungsausschluss ?? this.gewaehrleistungsausschluss,
    );
  }
}

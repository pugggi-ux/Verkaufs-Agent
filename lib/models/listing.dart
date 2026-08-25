enum ListingStatus { online, reserviert, verkauft, versendet }

ListingStatus listingStatusFromString(String value) {
  return ListingStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ListingStatus.online,
  );
}

class Listing {
  final String id;
  final String userId;
  final String gameId;
  final DateTime inseratDatum;
  final DateTime ablaufdatum;
  final ListingStatus status;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.inseratDatum,
    required this.ablaufdatum,
    required this.status,
    required this.createdAt,
  });

  bool get erinnerungFaellig {
    final tageBisAblauf = ablaufdatum.difference(DateTime.now()).inDays;
    return status == ListingStatus.online && tageBisAblauf <= 8 && tageBisAblauf >= 0;
  }

  bool get abgelaufen =>
      status == ListingStatus.online && DateTime.now().isAfter(ablaufdatum);

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      gameId: map['game_id'] as String,
      inseratDatum: DateTime.parse(map['inserat_datum'] as String),
      ablaufdatum: DateTime.parse(map['ablaufdatum'] as String),
      status: listingStatusFromString(map['status'] as String? ?? 'online'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

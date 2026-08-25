import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class BggCollectionItem {
  final int bggId;
  final String name;
  final String? imageUrl;
  final double? pricePaid;
  final DateTime? acquisitionDate;

  const BggCollectionItem({
    required this.bggId,
    required this.name,
    this.imageUrl,
    this.pricePaid,
    this.acquisitionDate,
  });
}

/// Client für die BoardGameGeek XMLAPI2, Collection-Endpoint.
///
/// BGG beantwortet eine frische Collection-Anfrage oft zunächst mit
/// HTTP 202 ("Anfrage wird verarbeitet") und liefert die eigentlichen
/// Daten erst bei einem erneuten Abruf kurz danach – daher der Retry-Loop.
class BggService {
  static const _baseUrl = 'https://boardgamegeek.com/xmlapi2/collection';

  Future<List<BggCollectionItem>> fetchCollection(
    String username, {
    int maxRetries = 6,
    Duration retryDelay = const Duration(seconds: 3),
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?username=${Uri.encodeQueryComponent(username)}'
      '&own=1&stats=1&showprivate=1',
    );

    http.Response? response;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      response = await http.get(uri);
      if (response.statusCode == 200) {
        break;
      }
      if (response.statusCode == 202) {
        await Future.delayed(retryDelay);
        continue;
      }
      throw BggSyncException(
        'BGG-Sync fehlgeschlagen (HTTP ${response.statusCode}) für Nutzer "$username".',
      );
    }

    if (response == null || response.statusCode != 200) {
      throw BggSyncException(
        'BGG-Sammlung konnte nicht geladen werden (Timeout nach $maxRetries Versuchen). '
        'Bitte später erneut versuchen.',
      );
    }

    return _parseCollection(response.body);
  }

  List<BggCollectionItem> _parseCollection(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);
    final items = document.findAllElements('item');
    final result = <BggCollectionItem>[];

    for (final item in items) {
      final bggIdStr = item.getAttribute('objectid');
      if (bggIdStr == null) continue;
      final bggId = int.tryParse(bggIdStr);
      if (bggId == null) continue;

      final name = item.findElements('name').firstOrNull?.innerText.trim() ?? 'Unbekanntes Spiel';
      final imageUrl = item.findElements('image').firstOrNull?.innerText.trim();

      double? pricePaid;
      DateTime? acquisitionDate;
      final privateInfo = item.findElements('privateinfo').firstOrNull;
      if (privateInfo != null) {
        final priceStr = privateInfo.getAttribute('pricepaid');
        if (priceStr != null && priceStr.isNotEmpty) {
          pricePaid = double.tryParse(priceStr);
        }
        final acqDateStr = privateInfo.getAttribute('acquisitiondate');
        if (acqDateStr != null && acqDateStr.isNotEmpty) {
          acquisitionDate = DateTime.tryParse(acqDateStr);
        }
      }

      result.add(BggCollectionItem(
        bggId: bggId,
        name: name,
        imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
        pricePaid: pricePaid,
        acquisitionDate: acquisitionDate,
      ));
    }

    return result;
  }
}

class BggSyncException implements Exception {
  final String message;
  const BggSyncException(this.message);

  @override
  String toString() => message;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

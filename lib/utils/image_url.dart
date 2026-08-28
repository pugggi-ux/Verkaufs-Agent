/// BGGs Bilder-CDN liefert keine CORS-Freigabe, wodurch Flutter Web
/// (CanvasKit-Renderer) die Cover-Bilder nicht laden kann – der Browser
/// blockt das Dekodieren von Cross-Origin-Bildern ohne
/// `Access-Control-Allow-Origin`-Header. images.weserv.nl spiegelt Bilder
/// mit korrektem CORS-Header, daher leiten wir Cover-URLs dort durch.
String? corsProxiedImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final ohneSchema = url.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(ohneSchema)}';
}

import 'package:url_launcher/url_launcher.dart';

class MapService {
  MapService._();

  static Future<bool> openAddress({
    required String address,
    String? city,
    String? label,
  }) async {
    final queryParts = [
      if (label != null && label.trim().isNotEmpty) label.trim(),
      address.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
      'Colombia',
    ].where((part) => part.isNotEmpty).join(', ');

    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': queryParts},
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:activ_user_app/core/network/api_url_builder.dart';

/// Resolves media URLs returned by the ACTIV API.
///
/// The backend returns relative media paths (e.g. `/api/v1/media/icons/...`)
/// unless `MEDIA_BASE_URL` is configured. This helper turns those into
/// absolute URLs using the app's configured API base so the device can fetch
/// them directly (works offline-ready via the caching image widgets).
class ApiMedia {
  ApiMedia._();

  /// Base origin, e.g. `http://10.0.2.2:3000`.
  static String get _origin {
    return apiOriginFromBaseUrl(dotenv.env['API_BASE_URL']);
  }

  /// Converts a relative `/api/v1/media/...` url to an absolute url. Absolute
  /// http(s) urls and local `assets/...` paths are returned unchanged.
  static String resolve(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('assets/')) return url;
    if (url.startsWith('/api/v1')) return '$_origin$url';
    return url;
  }

  /// True when [url] looks like a network svg (served by the media API).
  static bool isSvg(String url) => url.toLowerCase().endsWith('.svg');

  /// Builds a media icon url for a sport code, e.g. `football_turf` ->
  /// `/api/v1/media/icons/football-turf.svg`. Resolution against the API base
  /// is deferred to [resolve] after the backend decides the real extension.
  static String relativeSportIcon(String sportCode) {
    final key = sportCode.toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');
    return '/api/v1/media/icons/$key.svg';
  }

  /// Builds a media amenity icon url from the amenity display name.
  static String relativeAmenityIcon(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    if (slug.isEmpty) return '';
    return '/api/v1/media/amenities/$slug.svg';
  }
}

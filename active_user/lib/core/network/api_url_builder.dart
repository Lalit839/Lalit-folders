const String defaultApiBaseUrl = 'http://10.0.2.2:3000/api/v1';
const String apiVersionPath = '/api/v1';

String normalizeApiBaseUrl(String? configuredBaseUrl) {
  var baseUrl = (configuredBaseUrl?.trim().isNotEmpty ?? false)
      ? configuredBaseUrl!.trim()
      : defaultApiBaseUrl;

  baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  while (baseUrl.endsWith(apiVersionPath)) {
    baseUrl = baseUrl.substring(0, baseUrl.length - apiVersionPath.length);
    baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  return '$baseUrl$apiVersionPath';
}

String normalizeApiPath(String path) {
  var normalized = path.trim().replaceFirst(RegExp(r'^/+'), '');
  normalized = normalized.replaceFirst(RegExp(r'^(api/v1)(/+|$)'), '');
  normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
  return normalized.isEmpty ? '' : '/$normalized';
}

Uri buildApiUri(
  String configuredBaseUrl,
  String path, {
  Map<String, String>? query,
}) {
  final normalizedBaseUrl = normalizeApiBaseUrl(configuredBaseUrl);
  final normalizedPath = normalizeApiPath(path);
  return Uri.parse('$normalizedBaseUrl$normalizedPath').replace(
    queryParameters: query,
  );
}

String apiOriginFromBaseUrl(String? configuredBaseUrl) {
  final normalizedBaseUrl = normalizeApiBaseUrl(configuredBaseUrl);
  return normalizedBaseUrl.substring(
    0,
    normalizedBaseUrl.length - apiVersionPath.length,
  );
}

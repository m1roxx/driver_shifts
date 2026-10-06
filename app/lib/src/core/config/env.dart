final class Env {
  Env({required String apiBaseUrl}) : apiBaseUrl = _httpUrl(apiBaseUrl);

  factory Env.fromDartDefines() =>
      Env(apiBaseUrl: const String.fromEnvironment('API_BASE_URL'));

  final Uri apiBaseUrl;

  static Uri _httpUrl(String value) {
    final url = Uri.tryParse(value);
    final isHttp =
        url != null &&
        (url.isScheme('http') || url.isScheme('https')) &&
        url.host.isNotEmpty;
    if (!isHttp) {
      throw ArgumentError.value(
        value,
        'API_BASE_URL',
        'Expected an http(s) URL. '
            'Run with --dart-define-from-file=env/<name>.json',
      );
    }
    return url;
  }
}

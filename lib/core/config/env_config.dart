
class EnvConfig {
  static const String _defaultUrl = 'https://nagarikplus.techprocod.com.np/api/v1/';

  static String get baseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : _defaultUrl;

  static const String baseUrlDev = _defaultUrl;
  static const String baseUrlStaging = _defaultUrl;
  static const String baseUrlProd = _defaultUrl;
}

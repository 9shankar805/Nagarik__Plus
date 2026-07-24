
class EnvConfig {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');
  static const String baseUrlDev = 'http://10.0.2.2:8000/api/v1';
  static const String baseUrlStaging = 'https://staging.nagarikplus.com/api/v1';
  static const String baseUrlProd = 'https://api.nagarikplus.com/api/v1';
}

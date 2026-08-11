/// Network service configuration.
class AppConfig {
  const AppConfig._();

  /// Base URL of the POS backend API.
  ///
  /// Override in real deployments, e.g. via
  /// `--dart-define=API_BASE_URL=https://api.example.com`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
// TD TRADER - Global Application Configuration
import 'config_storage_stub.dart'
    if (dart.library.io) 'config_storage_io.dart' as storage;

class AppConfig {
  static const String appName = 'TD TRADER';
  static const String appVersion = '2.0.0';
  static const String tagline = 'Trade Smarter. Think Faster. Let AI Explain.';
  static const String owner = 'TechDaddy';
  static const String copyright =
      'Copyright © 2026 TechDaddy. All rights reserved.';
  static const String organization = 'TechDaddy Fintech Systems';

  // API & WebSocket Endpoints (Dynamically configurable & persisted across restarts)
  static String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api/v1';
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws') + '/ws';
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static Future<void> loadSavedBaseUrl() async {
    final saved = await storage.loadServerUrl();
    if (saved != null && saved.isNotEmpty) {
      baseUrl = _normalizeUrl(saved);
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    baseUrl = _normalizeUrl(newUrl);
    await storage.saveServerUrl(baseUrl);
  }

  static String _normalizeUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  // Supported Markets
  static const List<String> marketCategories = [
    'ALL',
    'FOREX',
    'SYNTHETICS',
    'CRYPTO',
    'METALS',
    'INDICES',
    'COMMODITIES'
  ];

  // Supported Timeframes
  static const List<String> timeframes = [
    'M5',
    'M15',
    'M30',
    'H1',
    'H4',
    'D1'
  ];
}

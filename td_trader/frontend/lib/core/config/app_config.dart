// TD TRADER - Global Application Configuration
class AppConfig {
  static const String appName = 'TD TRADER';
  static const String appVersion = '2.0.0';
  static const String tagline = 'Trade Smarter. Think Faster. Let AI Explain.';
  static const String owner = 'TechDaddy';
  static const String copyright = 'Copyright © 2026 TechDaddy. All rights reserved.';
  static const String organization = 'TechDaddy Fintech Systems';
  
  // API & WebSocket Endpoints (Dynamically configurable at runtime)
  static String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api/v1';
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws') + '/ws';
  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  
  static void setBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    baseUrl = trimmed;
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

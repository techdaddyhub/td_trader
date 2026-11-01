// TD TRADER - Global Application Configuration
class AppConfig {
  static const String appName = 'TD TRADER';
  static const String appVersion = '2.0.0';
  static const String tagline = 'Trade Smarter. Think Faster. Let AI Explain.';
  static const String owner = 'TechDaddy';
  static const String copyright = 'Copyright © 2026 TechDaddy. All rights reserved.';
  static const String organization = 'TechDaddy Fintech Systems';
  
  // API & WebSocket Endpoints (Configurable for local / VPS / production)
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api/v1';
  static const String wsUrl = 'ws://127.0.0.1:8000/ws';
  
  // Supported Markets
  static const List<String> marketCategories = [
    'ALL',
    'FOREX',
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


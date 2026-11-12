// TD TRADER - Frontend API & Network Service Layer
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  String? _authToken;
  static const Duration _timeout = Duration(seconds: 12);

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  String _extractDetail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return '$fallback (HTTP ${response.statusCode})';
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception(_extractDetail(response, 'Login failed'));
  }

  Future<Map<String, dynamic>> register(
      String email, String fullName, String password) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'email': email, 'full_name': fullName, 'password': password}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception(_extractDetail(response, 'Registration failed'));
  }

  // --- Module 1: Scanner ---
  Future<List<SignalModel>> getOpportunities({
    String? category,
    String? instrument,
    String? timeframe,
    String? direction,
    String? strategy,
    double minScore = 60.0,
  }) async {
    final queryParams = <String, String>{
      'min_score': minScore.toString(),
    };
    if (category != null && category != 'ALL') {
      queryParams['category'] = category;
    }
    if (instrument != null) queryParams['instrument'] = instrument;
    if (timeframe != null) queryParams['timeframe'] = timeframe;
    if (direction != null) queryParams['direction'] = direction;
    if (strategy != null) queryParams['strategy'] = strategy;

    final uri = Uri.parse(
            '${AppConfig.baseUrl}${AppConfig.apiPrefix}/scanner/opportunities')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => SignalModel.fromJson(e)).toList();
    }
    throw Exception(_extractDetail(response, 'Failed to load opportunities'));
  }

  Future<void> triggerScanNow() async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/scanner/scan-now'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception(_extractDetail(response, 'Scan failed'));
    }
  }

  // --- Module 2: Voice ---
  Future<Map<String, dynamic>> sendVoiceQuery(
      String query, String personality) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/voice/query'),
          headers: _headers,
          body: jsonEncode({'query': query, 'voice_personality': personality}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Voice query failed'));
  }

  // --- Module 3: Smart Risk Guardian ---
  Future<RiskConfigModel> getRiskConfig(int accountId) async {
    final response = await http
        .get(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/risk/config/$accountId'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return RiskConfigModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractDetail(response, 'Failed to load risk config'));
  }

  Future<void> executeEmergencyAction(
      int accountId, String action, bool confirmCloseAll) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/risk/emergency-action/$accountId'),
          headers: _headers,
          body: jsonEncode(
              {'action': action, 'confirm_close_all': confirmCloseAll}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(_extractDetail(response, 'Emergency action failed'));
    }
  }

  // --- Module 4: Backtesting ---
  Future<Map<String, dynamic>> runBacktest(Map<String, dynamic> params) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/backtest/run'),
          headers: _headers,
          body: jsonEncode(params),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Backtest execution failed'));
  }

  Future<List<dynamic>> compareStrategies(
      String symbol, List<String> strategies) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/backtest/compare'),
          headers: _headers,
          body: jsonEncode({'instrument': symbol, 'strategies': strategies}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Strategy comparison failed'));
  }

  // --- Module 5: Accounts & Trading ---
  Future<List<TradingAccountModel>> getAccounts() async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => TradingAccountModel.fromJson(e)).toList();
    }
    throw Exception(_extractDetail(response, 'Failed to fetch accounts'));
  }

  Future<void> addAccount(Map<String, dynamic> accountData) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/'),
          headers: _headers,
          body: jsonEncode(accountData),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(_extractDetail(response, 'Failed to add account'));
    }
  }

  // --- Deriv Broker Endpoints ---
  Future<Map<String, dynamic>> verifyDerivToken(String apiToken,
      {String appId = '1089'}) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/brokers/deriv/verify-token'),
          headers: _headers,
          body: jsonEncode({'api_token': apiToken, 'app_id': appId}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Deriv verification failed'));
  }

  Future<Map<String, dynamic>> syncDerivTicks(
      {List<String>? symbols, String appId = '1089'}) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/brokers/deriv/sync-ticks'),
          headers: _headers,
          body: jsonEncode({'symbols': symbols, 'app_id': appId}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Deriv sync failed'));
  }

  // --- MetaTrader 4 / 5 Real EA Bridge Status ---
  Future<Map<String, dynamic>> getBridgeStatus() async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/bridge/status'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Failed to fetch bridge status'));
  }

  Future<void> toggleAutoTrading(int accountId, bool enabled) async {
    final response = await http
        .put(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/$accountId/toggle-auto-trading'),
          headers: _headers,
          body: jsonEncode({'enabled': enabled}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(_extractDetail(response, 'Failed to toggle auto trading'));
    }
  }

  Future<void> authorizeLiveTrading(int accountId, bool authorized) async {
    final response = await http
        .put(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/$accountId/authorize-live'),
          headers: _headers,
          body: jsonEncode({'authorized': authorized}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(
          _extractDetail(response, 'Failed to authorize live account'));
    }
  }

  Future<List<PositionModel>> getPositions(int accountId) async {
    final response = await http
        .get(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/positions/$accountId'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => PositionModel.fromJson(e)).toList();
    }
    throw Exception(_extractDetail(response, 'Failed to load positions'));
  }

  Future<Map<String, dynamic>> executeTrade(
      Map<String, dynamic> tradeData) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/execute'),
          headers: _headers,
          body: jsonEncode(tradeData),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Trade execution failed'));
  }

  Future<void> closePosition(int positionId) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/positions/close/$positionId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_extractDetail(response, 'Failed to close position'));
    }
  }

  Future<List<dynamic>> getJournalEntries() async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/journal/'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_extractDetail(response, 'Failed to load trading journal'));
  }

  Future<Map<String, dynamic>> checkHealth([String? customUrl]) async {
    var target = (customUrl ?? AppConfig.baseUrl).trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'http://$target';
    }
    final url = target.endsWith('/') ? '${target}health' : '$target/health';
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Status code: ${response.statusCode}');
  }
}

final apiService = ApiService();

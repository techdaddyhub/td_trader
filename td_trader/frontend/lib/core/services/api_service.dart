// TD TRADER - Frontend API & Network Service Layer
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  String? _authToken;

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

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception('Login failed: ${response.body}');
  }

  Future<Map<String, dynamic>> register(String email, String fullName, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'full_name': fullName, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception('Registration failed: ${response.body}');
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
    if (category != null && category != 'ALL') queryParams['category'] = category;
    if (instrument != null) queryParams['instrument'] = instrument;
    if (timeframe != null) queryParams['timeframe'] = timeframe;
    if (direction != null) queryParams['direction'] = direction;
    if (strategy != null) queryParams['strategy'] = strategy;

    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/scanner/opportunities').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => SignalModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load scanner opportunities');
  }

  Future<void> triggerScanNow() async {
    await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/scanner/scan-now'),
      headers: _headers,
    );
  }

  // --- Module 2: Voice ---
  Future<Map<String, dynamic>> sendVoiceQuery(String query, String personality) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/voice/query'),
      headers: _headers,
      body: jsonEncode({'query': query, 'voice_personality': personality}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Voice query failed');
  }

  // --- Module 3: Smart Risk Guardian ---
  Future<RiskConfigModel> getRiskConfig(int accountId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/risk/config/$accountId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return RiskConfigModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load risk config');
  }

  Future<void> executeEmergencyAction(int accountId, String action, bool confirmCloseAll) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/risk/emergency-action/$accountId'),
      headers: _headers,
      body: jsonEncode({'action': action, 'confirm_close_all': confirmCloseAll}),
    );
    if (response.statusCode != 200) {
      throw Exception('Emergency action failed: ${response.body}');
    }
  }

  // --- Module 4: Backtesting ---
  Future<Map<String, dynamic>> runBacktest(Map<String, dynamic> params) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/backtest/run'),
      headers: _headers,
      body: jsonEncode(params),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Backtest execution failed: ${response.body}');
  }

  Future<List<dynamic>> compareStrategies(String symbol, List<String> strategies) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/backtest/compare'),
      headers: _headers,
      body: jsonEncode({'instrument': symbol, 'strategies': strategies}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Strategy comparison failed');
  }

  // --- Module 5: Accounts & Trading ---
  Future<List<TradingAccountModel>> getAccounts() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => TradingAccountModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch accounts');
  }

  Future<void> addAccount(Map<String, dynamic> accountData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/'),
      headers: _headers,
      body: jsonEncode(accountData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add account: ${response.body}');
    }
  }

  Future<void> toggleAutoTrading(int accountId, bool enabled) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/$accountId/toggle-auto-trading'),
      headers: _headers,
      body: jsonEncode({'enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle auto trading: ${response.body}');
    }
  }

  Future<void> authorizeLiveTrading(int accountId, bool authorized) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/accounts/$accountId/authorize-live'),
      headers: _headers,
      body: jsonEncode({'authorized': authorized}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to authorize live account: ${response.body}');
    }
  }

  Future<List<PositionModel>> getPositions(int accountId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/positions/$accountId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => PositionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load positions');
  }

  Future<void> executeTrade(Map<String, dynamic> tradeData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/execute'),
      headers: _headers,
      body: jsonEncode(tradeData),
    );
    if (response.statusCode != 200) {
      throw Exception('Trade execution failed: ${response.body}');
    }
  }

  Future<void> closePosition(int positionId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}/trading/positions/close/$positionId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to close position: ${response.body}');
    }
  }
}

final apiService = ApiService();


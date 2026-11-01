// TD TRADER - Unified State Management Providers
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ScannerProvider extends ChangeNotifier {
  List<SignalModel> _opportunities = [];
  bool _isLoading = false;
  String _selectedCategory = 'ALL';
  String _selectedTimeframe = 'H1';
  double _minScore = 60.0;

  List<SignalModel> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedTimeframe => _selectedTimeframe;
  double get minScore => _minScore;

  Future<void> fetchOpportunities() async {
    _isLoading = true;
    notifyListeners();
    try {
      _opportunities = await apiService.getOpportunities(
        category: _selectedCategory,
        timeframe: _selectedTimeframe,
        minScore: _minScore,
      );
    } catch (e) {
      debugPrint('Error fetching opportunities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    fetchOpportunities();
  }

  void setTimeframe(String tf) {
    _selectedTimeframe = tf;
    fetchOpportunities();
  }

  void setMinScore(double score) {
    _minScore = score;
    fetchOpportunities();
  }
}

class VoiceProvider extends ChangeNotifier {
  bool _isListening = false;
  bool _isSpeaking = false;
  String _selectedPersonality = 'Aria_Fintech_Pro';
  double _speechSpeed = 1.05;
  double _volume = 1.0;
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Hello Trader. I am your TD AI Voice analyst. Ask me about any market setup, risk status, or trade rationale.'
    }
  ];

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get selectedPersonality => _selectedPersonality;
  double get speechSpeed => _speechSpeed;
  double get volume => _volume;
  List<Map<String, String>> get messages => _messages;

  void setPersonality(String p) {
    _selectedPersonality = p;
    notifyListeners();
  }

  void setSpeed(double s) {
    _speechSpeed = s;
    notifyListeners();
  }

  void setVolume(double v) {
    _volume = v;
    notifyListeners();
  }

  void toggleListening() {
    _isListening = !_isListening;
    notifyListeners();
  }

  void interruptSpeech() {
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    _messages.add({'role': 'user', 'text': question});
    _isSpeaking = true;
    notifyListeners();

    try {
      final res = await apiService.sendVoiceQuery(question, _selectedPersonality);
      _messages.add({'role': 'assistant', 'text': res['response_text']});
    } catch (e) {
      _messages.add({'role': 'assistant', 'text': 'Unable to connect to Voice Engine: $e'});
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }
}

class RiskProvider extends ChangeNotifier {
  RiskConfigModel? _config;
  bool _isLoading = false;

  RiskConfigModel? get config => _config;
  bool get isLoading => _isLoading;

  Future<void> fetchConfig(int accountId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await apiService.getRiskConfig(accountId);
    } catch (e) {
      debugPrint('Error fetching risk config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerEmergency(int accountId, String action, bool confirmCloseAll) async {
    try {
      await apiService.executeEmergencyAction(accountId, action, confirmCloseAll);
      await fetchConfig(accountId);
    } catch (e) {
      rethrow;
    }
  }
}

class AccountProvider extends ChangeNotifier {
  List<TradingAccountModel> _accounts = [];
  TradingAccountModel? _activeAccount;
  List<PositionModel> _positions = [];
  bool _isLoading = false;

  List<TradingAccountModel> get accounts => _accounts;
  TradingAccountModel? get activeAccount => _activeAccount;
  List<PositionModel> get positions => _positions;
  bool get isLoading => _isLoading;

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accounts = await apiService.getAccounts();
      if (_accounts.isNotEmpty && _activeAccount == null) {
        _activeAccount = _accounts.first;
      }
      if (_activeAccount != null) {
        await loadPositions(_activeAccount!.id);
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchActiveAccount(TradingAccountModel account) {
    _activeAccount = account;
    loadPositions(account.id);
    notifyListeners();
  }

  Future<void> loadPositions(int accountId) async {
    try {
      _positions = await apiService.getPositions(accountId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading positions: $e');
    }
  }

  Future<void> toggleAutoTrading(bool enabled) async {
    if (_activeAccount == null) return;
    await apiService.toggleAutoTrading(_activeAccount!.id, enabled);
    await loadAccounts();
  }

  Future<void> authorizeLive(bool authorized) async {
    if (_activeAccount == null) return;
    await apiService.authorizeLiveTrading(_activeAccount!.id, authorized);
    await loadAccounts();
  }

  Future<void> closePosition(int positionId) async {
    await apiService.closePosition(positionId);
    if (_activeAccount != null) {
      await loadPositions(_activeAccount!.id);
    }
  }
}


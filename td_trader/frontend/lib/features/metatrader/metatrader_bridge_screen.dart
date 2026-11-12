// TD TRADER - MetaTrader 4 & 5 Bridge Integration Center
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class MetaTraderBridgeScreen extends StatefulWidget {
  const MetaTraderBridgeScreen({super.key});

  @override
  State<MetaTraderBridgeScreen> createState() => _MetaTraderBridgeScreenState();
}

class _MetaTraderBridgeScreenState extends State<MetaTraderBridgeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _onlineCount = 0;
  List<dynamic> _terminals = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadBridgeStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _loadBridgeStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBridgeStatus({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final status = await apiService.getBridgeStatus();
      if (!mounted) return;
      setState(() {
        _onlineCount = (status['online_count'] as num?)?.toInt() ?? 0;
        _terminals = (status['terminals'] as List?) ?? [];
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorMessage != null;
    final bool isOnline = !hasError && _onlineCount > 0;
    final Color statusColor = hasError
        ? AppColors.bearishRed
        : (isOnline ? AppColors.bullishGreen : AppColors.warningAmber);
    final String statusLabel = hasError
        ? 'SERVER OFFLINE'
        : (isOnline ? 'ONLINE ($_onlineCount EA)' : 'WAITING FOR EA');

    return Scaffold(
      appBar: AppBar(
        title: const Text('DERIV & METATRADER BRIDGE CENTER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
            tooltip: 'Refresh Bridge Status',
            onPressed: _isLoading ? null : () => _loadBridgeStatus(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bridge Status Card
          Card(
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bolt, color: AppColors.primaryCyan),
                          SizedBox(width: 8),
                          Text('LIVE EA BRIDGE STATUS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Cannot reach backend bridge endpoint: $_errorMessage',
                        style: const TextStyle(
                            color: AppColors.bearishRed, fontSize: 12),
                      ),
                    ),
                  _buildBridgeRow('Deriv Native WS API v3',
                      'wss://ws.derivws.com (Token Auth)', true),
                  const SizedBox(height: 8),
                  _buildBridgeRow('MT4 / MT5 WebRequest Bridge',
                      '/api/v1/bridge/mt/heartbeat', !hasError),
                  const SizedBox(height: 8),
                  _buildBridgeRow('Connected Active Terminals',
                      '$_onlineCount Live EA Session(s)', isOnline),
                  const SizedBox(height: 8),
                  _buildBridgeRow('Broker Execution Confirmation',
                      'Mandatory Ticket Receipt', true),
                  const SizedBox(height: 8),
                  _buildBridgeRow('Credential Security',
                      'AES-256 Fernet (In-Memory Only)', true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Connected Terminals Section
          const Text('CONNECTED MT4 / MT5 EA TERMINALS',
              style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 8),
          if (_isLoading && _terminals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryCyan)),
            )
          else if (_terminals.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No MT4 or MT5 Expert Advisor heartbeats detected yet.\n'
                'Attach TDTrader_Bridge_MT5 (.ex5) or TDTrader_Bridge_MT4 (.ex4) to any MetaTrader chart with AutoTrading enabled.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.5),
              ),
            )
          else
            ..._terminals.map((term) {
              final t = Map<String, dynamic>.from(term as Map);
              final isTermOnline = t['status'] == 'ONLINE';
              final bal = (t['balance'] as num?)?.toDouble() ?? 0.0;
              final eq = (t['equity'] as num?)?.toDouble() ?? 0.0;
              final age =
                  (t['seconds_since_heartbeat'] as num?)?.toInt() ?? 999;

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isTermOnline
                        ? AppColors.bullishGreen.withValues(alpha: 0.45)
                        : AppColors.warningAmber.withValues(alpha: 0.45),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    isTermOnline ? Icons.sensors : Icons.sensors_off,
                    color: isTermOnline
                        ? AppColors.bullishGreen
                        : AppColors.warningAmber,
                  ),
                  title: Text(
                    '${t['platform'] ?? 'MT5'} #${t['account_number'] ?? ''} (${t['broker'] ?? 'Broker'})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Server: ${t['server'] ?? ''} • Bal: \$${bal.toStringAsFixed(2)} | Eq: \$${eq.toStringAsFixed(2)} • ${age}s ago',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  trailing: Text(
                    isTermOnline ? 'ONLINE' : 'STALE',
                    style: TextStyle(
                      color: isTermOnline
                          ? AppColors.bullishGreen
                          : AppColors.warningAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),

          // Deriv Connection Guide
          const Text('DERIV BROKER SETUP (NATIVE API & DMT5)',
              style: TextStyle(
                  color: AppColors.binanceGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.binanceGold.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '• OPTION A — DERIV NATIVE API (No PC/MT5 Needed):\n'
              '  1. Log in at app.deriv.com -> Settings -> API Token.\n'
              '  2. Enable "Read" and "Trade" scopes and create your token.\n'
              '  3. In TD TRADER -> Connect Broker -> Choose "Deriv-API-Demo" or "Deriv-API-Live".\n'
              '  4. Paste the token and click VERIFY DERIV TOKEN & AUTO-FILL.\n\n'
              '• OPTION B — DERIV METATRADER 5 (DMT5 Synthetics / Financial):\n'
              '  1. Open Deriv MT5 on PC/VPS and attach TDTrader_Bridge_MT5.mq5.\n'
              '  2. Select preset "Deriv-MT5-Demo" (Deriv-Demo) or "Deriv-MT5-Live" (Deriv-Server).',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),

          // Expert Advisor Installation Instructions
          const Text('EXPERT ADVISOR (EA) INSTALLATION GUIDE',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Locate EA Files in your TD Trader installation:\n'
                  '   • td_trader/metatrader_bridge/experts/TDTrader_Bridge_MT4.mq4\n'
                  '   • td_trader/metatrader_bridge/experts/TDTrader_Bridge_MT5.mq5\n\n'
                  '2. In MetaTrader 4 / 5, click File -> Open Data Folder.\n\n'
                  '3. Paste the file into MQL4/Experts/ or MQL5/Experts/.\n\n'
                  '4. Go to Tools -> Options -> Expert Advisors:\n'
                  '   • Check "Allow automated trading"\n'
                  '   • Check "Allow WebRequest for listed URL" and add http://127.0.0.1:8000\n\n'
                  '5. Drag the EA onto any chart window to establish bridge connection.',
                  style:
                      TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBridgeRow(String name, String detail, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text(detail,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

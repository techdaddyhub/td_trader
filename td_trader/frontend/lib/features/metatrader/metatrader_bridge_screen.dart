// TD TRADER - MetaTrader 4 & 5 Bridge Integration Center
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MetaTraderBridgeScreen extends StatelessWidget {
  const MetaTraderBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DERIV & METATRADER BRIDGE CENTER'),
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
                          Text('ZERO-LATENCY BRIDGE STATUS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bullishGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.bullishGreen),
                        ),
                        child: const Text('ONLINE',
                            style: TextStyle(
                                color: AppColors.bullishGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _buildBridgeRow('Deriv Native WS API v3',
                      'wss://ws.derivws.com (Token Auth)', true),
                  const SizedBox(height: 8),
                  _buildBridgeRow('Deriv MT5 (DMT5)',
                      'Deriv-Demo / Deriv-Server (Port 5556)', true),
                  const SizedBox(height: 8),
                  _buildBridgeRow('MT4 Desktop Connector',
                      'Port 5555 (Encrypted TCP)', true),
                  const SizedBox(height: 8),
                  _buildBridgeRow('MT5 Desktop / VPS Connector',
                      'Port 5556 (Encrypted TCP)', true),
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
          const SizedBox(height: 20),

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

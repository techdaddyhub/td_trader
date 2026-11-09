// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Advanced MetaTrader 4 & 5 (Demo & Live) Account Connector
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../services/api_service.dart';

void showConnectMetaTraderDialog(BuildContext context) {
  final accountNumController = TextEditingController();
  final brokerController = TextEditingController(text: 'IC Markets (SC)');
  final serverController = TextEditingController(text: 'ICMarketsSC-Live01');
  final passwordController = TextEditingController();
  final balanceController = TextEditingController(text: '10000.00');
  
  String platform = 'MT5_LIVE';
  String currency = 'USD';
  String selectedPreset = 'ICMarkets-Live';
  bool isLiveAuthorized = false;
  bool isSubmitting = false;

  final Map<String, Map<String, String>> brokerPresets = {
    'ICMarkets-Live': {
      'broker': 'IC Markets (SC)',
      'server': 'ICMarketsSC-Live01',
      'platform': 'MT5_LIVE',
    },
    'ICMarkets-Demo': {
      'broker': 'IC Markets (SC)',
      'server': 'ICMarketsSC-Demo01',
      'platform': 'MT5_DEMO',
    },
    'FTMO-Server': {
      'broker': 'FTMO',
      'server': 'FTMO-Server',
      'platform': 'MT5_LIVE',
    },
    'FTMO-Demo': {
      'broker': 'FTMO',
      'server': 'FTMO-Demo',
      'platform': 'MT5_DEMO',
    },
    'MetaQuotes-Demo': {
      'broker': 'MetaQuotes Software',
      'server': 'MetaQuotes-Demo',
      'platform': 'MT5_DEMO',
    },
    'Exness-Real': {
      'broker': 'Exness Technologies',
      'server': 'Exness-Real1',
      'platform': 'MT5_LIVE',
    },
    'Exness-Trial': {
      'broker': 'Exness Technologies',
      'server': 'Exness-Trial',
      'platform': 'MT4_DEMO',
    },
    'Pepperstone-Live': {
      'broker': 'Pepperstone Group',
      'server': 'Pepperstone-Live01',
      'platform': 'MT4_LIVE',
    },
    'Pepperstone-Demo': {
      'broker': 'Pepperstone Group',
      'server': 'Pepperstone-Demo01',
      'platform': 'MT4_DEMO',
    },
    'FundedNext-Server': {
      'broker': 'FundedNext',
      'server': 'FundedNext-Server',
      'platform': 'MT5_LIVE',
    },
    'Custom Broker': {
      'broker': '',
      'server': '',
      'platform': 'MT5_LIVE',
    },
  };

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isLive = platform == 'MT4_LIVE' || platform == 'MT5_LIVE';

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLive ? AppColors.binanceGold : AppColors.bullishGreen,
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(
                isLive ? Icons.bolt : Icons.science,
                color: isLive ? AppColors.binanceGold : AppColors.bullishGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLive ? 'CONNECT LIVE METATRADER ACCOUNT' : 'CONNECT DEMO METATRADER ACCOUNT',
                  style: TextStyle(
                    color: isLive ? AppColors.binanceGold : AppColors.bullishGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Account Environment / Platform Selector
                  const Text('1. SELECT PLATFORM & ENVIRONMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.binanceGold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: platform,
                    decoration: const InputDecoration(labelText: 'Platform & Account Type'),
                    dropdownColor: AppColors.surface,
                    items: const [
                      DropdownMenuItem(
                        value: 'MT5_LIVE',
                        child: Text('⚡ MetaTrader 5 (MT5) - LIVE Real Capital', style: TextStyle(color: AppColors.binanceGold, fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: 'MT5_DEMO',
                        child: Text('🟢 MetaTrader 5 (MT5) - DEMO Account', style: TextStyle(color: AppColors.bullishGreen)),
                      ),
                      DropdownMenuItem(
                        value: 'MT4_LIVE',
                        child: Text('⚡ MetaTrader 4 (MT4) - LIVE Real Capital', style: TextStyle(color: AppColors.binanceGold, fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: 'MT4_DEMO',
                        child: Text('🟢 MetaTrader 4 (MT4) - DEMO Account', style: TextStyle(color: AppColors.bullishGreen)),
                      ),
                      DropdownMenuItem(
                        value: 'PAPER_TRADING',
                        child: Text('🛡️ TD Risk-Free Paper Simulator (\$10k)', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        platform = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Broker Preset Selector
                  const Text('2. BROKER / PROP FIRM PRESET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.binanceGold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPreset,
                    decoration: const InputDecoration(labelText: 'Quick Broker Presets'),
                    dropdownColor: AppColors.surface,
                    items: brokerPresets.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedPreset = val!;
                        final preset = brokerPresets[val]!;
                        if (val != 'Custom Broker') {
                          brokerController.text = preset['broker']!;
                          serverController.text = preset['server']!;
                          platform = preset['platform']!;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Credentials & Server Details
                  const Text('3. BROKER LOGIN & SERVER CREDENTIALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.binanceGold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accountNumController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Account Login / Account Number',
                      hintText: 'e.g. 5829103',
                      prefixIcon: Icon(Icons.person, color: AppColors.binanceGold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brokerController,
                          decoration: const InputDecoration(labelText: 'Broker Name', hintText: 'IC Markets'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: serverController,
                          decoration: const InputDecoration(labelText: 'Server Name', hintText: 'ICMarketsSC-Live01'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (Encrypted AES-256)',
                      hintText: 'Master or Investor Password',
                      prefixIcon: Icon(Icons.lock, color: AppColors.binanceGold),
                      helperText: 'Encrypted at rest immediately. Never stored plaintext.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: balanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Balance / Equity', prefixText: '\$'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currency,
                          decoration: const InputDecoration(labelText: 'Currency'),
                          dropdownColor: AppColors.surface,
                          items: ['USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => currency = val!),
                        ),
                      ),
                    ],
                  ),

                  // 4. Live Capital Protection Notice
                  if (isLive) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.binanceGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.binanceGold),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber, color: AppColors.binanceGold, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LIVE CAPITAL WARNING',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.binanceGold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You are connecting a LIVE real-money broker account. Orders executed will risk actual capital. '
                            'The Smart Risk Guardian will enforce lot sizing and daily loss limits.',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: isLiveAuthorized,
                                activeColor: AppColors.binanceGold,
                                checkColor: Colors.black,
                                onChanged: (val) => setDialogState(() => isLiveAuthorized = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'I authorize live broker execution with Risk Guardian active.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLive ? AppColors.binanceGold : AppColors.bullishGreen,
                foregroundColor: const Color(0xFF0B0E11),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (accountNumController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an account login number.')),
                        );
                        return;
                      }

                      if (isLive && !isLiveAuthorized) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please check the live authorization box to confirm real capital connection.'),
                            backgroundColor: AppColors.bearishRed,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await apiService.addAccount({
                          'account_number': accountNumController.text.trim(),
                          'broker_name': brokerController.text.trim(),
                          'server': serverController.text.trim(),
                          'platform': platform,
                          'currency': currency,
                          'password': passwordController.text,
                          'balance': double.tryParse(balanceController.text) ?? 10000.0,
                          'is_auto_trading_enabled': isLive ? isLiveAuthorized : true,
                          'is_authorized_live': isLiveAuthorized,
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          await Provider.of<AccountProvider>(context, listen: false).loadAccounts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('MetaTrader $platform account #${accountNumController.text} connected!'),
                              backgroundColor: AppColors.bullishGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connection error: $e'), backgroundColor: AppColors.bearishRed),
                          );
                        }
                      }
                    },
              child: Text(
                isLive ? 'CONNECT LIVE ACCOUNT' : 'CONNECT DEMO ACCOUNT',
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ],
        );
      },
    ),
  );
}

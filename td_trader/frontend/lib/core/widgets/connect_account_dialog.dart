// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Unified Broker Connector (MetaTrader 4/5 & Deriv API Demo/Live)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../services/api_service.dart';

void showConnectMetaTraderDialog(BuildContext context) {
  final accountNumController = TextEditingController();
  final brokerController = TextEditingController(text: 'Deriv (SVG) LLC');
  final serverController = TextEditingController(text: 'Deriv-Demo');
  final passwordController = TextEditingController();
  final derivAppIdController = TextEditingController(text: '1089');
  final balanceController = TextEditingController(text: '10000.00');

  String platform = 'MT5_DEMO';
  String currency = 'USD';
  String selectedPreset = 'Deriv-MT5-Demo';
  bool isLiveAuthorized = false;
  bool isSubmitting = false;
  bool isVerifyingDeriv = false;
  String? derivVerifyStatus;
  bool derivVerifyOk = false;

  final Map<String, Map<String, String>> brokerPresets = {
    'Deriv-MT5-Demo': {
      'broker': 'Deriv (SVG) LLC',
      'server': 'Deriv-Demo',
      'platform': 'MT5_DEMO',
    },
    'Deriv-MT5-Live': {
      'broker': 'Deriv (SVG) LLC',
      'server': 'Deriv-Server',
      'platform': 'MT5_LIVE',
    },
    'Deriv-MT5-Live-02': {
      'broker': 'Deriv (SVG) LLC',
      'server': 'Deriv-Server-02',
      'platform': 'MT5_LIVE',
    },
    'Deriv-MT5-SVG': {
      'broker': 'Deriv (SVG) LLC',
      'server': 'DerivSVG-Server',
      'platform': 'MT5_LIVE',
    },
    'Deriv-API-Demo (Token)': {
      'broker': 'Deriv Native WS API',
      'server': 'ws.derivws.com',
      'platform': 'DERIV_API_DEMO',
    },
    'Deriv-API-Live (Real CR Token)': {
      'broker': 'Deriv Native WS API',
      'server': 'ws.derivws.com',
      'platform': 'DERIV_API_LIVE',
    },
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
        final isDerivApi = platform.startsWith('DERIV_API');
        final isLive = platform.contains('LIVE');

        return AlertDialog(
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isDerivApi
                        ? (isLive
                            ? 'CONNECT DERIV LIVE API'
                            : 'CONNECT DERIV DEMO API')
                        : (isLive
                            ? 'CONNECT LIVE BROKER'
                            : 'CONNECT DEMO BROKER'),
                    style: TextStyle(
                      color: isLive
                          ? AppColors.binanceGold
                          : AppColors.bullishGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 460,
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Account Environment / Platform Selector
                  const Text('1. SELECT PLATFORM & ENVIRONMENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.binanceGold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('platform_$platform'),
                    isExpanded: true,
                    menuMaxHeight: 280,
                    initialValue: platform,
                    decoration: const InputDecoration(
                        labelText: 'Platform & Environment'),
                    dropdownColor: AppColors.surface,
                    items: const [
                      DropdownMenuItem(
                        value: 'DERIV_API_DEMO',
                        child: Text('🟢 Deriv Native API - DEMO (Token)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.bullishGreen, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'DERIV_API_LIVE',
                        child: Text('⚡ Deriv Native API - LIVE (Real Token)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.binanceGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'MT5_LIVE',
                        child: Text('⚡ MetaTrader 5 (MT5) - LIVE Real',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.binanceGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'MT5_DEMO',
                        child: Text('🟢 MetaTrader 5 (MT5) - DEMO',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.bullishGreen, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'MT4_LIVE',
                        child: Text('⚡ MetaTrader 4 (MT4) - LIVE Real',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.binanceGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'MT4_DEMO',
                        child: Text('🟢 MetaTrader 4 (MT4) - DEMO',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: AppColors.bullishGreen, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'PAPER_TRADING',
                        child: Text('🛡️ TD Risk-Free Paper (\$10,000)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        platform = val!;
                        derivVerifyStatus = null;
                        if (platform.startsWith('DERIV_API')) {
                          brokerController.text = 'Deriv Native WS API';
                          serverController.text =
                              'ws.derivws.com (AppID: ${derivAppIdController.text.trim()})';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Broker Preset Selector
                  const Text('2. BROKER / DERIV / PROP FIRM PRESET',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.binanceGold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('preset_$selectedPreset'),
                    isExpanded: true,
                    menuMaxHeight: 280,
                    initialValue: selectedPreset,
                    decoration: const InputDecoration(
                        labelText: 'Quick Broker Presets'),
                    dropdownColor: AppColors.surface,
                    items: brokerPresets.keys
                        .map((k) => DropdownMenuItem(
                              value: k,
                              child: Text(
                                k,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedPreset = val!;
                        final preset = brokerPresets[val]!;
                        derivVerifyStatus = null;
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
                  Text(
                      isDerivApi
                          ? '3. DERIV API TOKEN & ACCOUNT VERIFICATION'
                          : '3. BROKER LOGIN & SERVER CREDENTIALS',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.binanceGold)),
                  const SizedBox(height: 6),

                  if (isDerivApi) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Create a Deriv API Token at app.deriv.com/account/api-token with Read + Trade scopes, then click VERIFY TOKEN to auto-load your CR/VRTC account.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Deriv API Token (AES-256)',
                              hintText: 'Paste token from app.deriv.com',
                              prefixIcon: Icon(Icons.vpn_key,
                                  color: AppColors.binanceGold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: derivAppIdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'App ID',
                              hintText: '1089',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.binanceGold,
                          side: const BorderSide(color: AppColors.binanceGold),
                        ),
                        icon: isVerifyingDeriv
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.binanceGold),
                              )
                            : const Icon(Icons.verified_user, size: 17),
                        label: Text(
                          isVerifyingDeriv
                              ? 'VERIFYING WITH DERIV WS...'
                              : 'VERIFY DERIV TOKEN & AUTO-FILL',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        onPressed: isVerifyingDeriv
                            ? null
                            : () async {
                                final token = passwordController.text.trim();
                                final appId =
                                    derivAppIdController.text.trim().isEmpty
                                        ? '1089'
                                        : derivAppIdController.text.trim();
                                if (token.isEmpty) {
                                  setDialogState(() {
                                    derivVerifyOk = false;
                                    derivVerifyStatus =
                                        'Please paste your Deriv API token first.';
                                  });
                                  return;
                                }
                                setDialogState(() {
                                  isVerifyingDeriv = true;
                                  derivVerifyStatus = null;
                                });
                                try {
                                  final info = await apiService.verifyDerivToken(
                                      token,
                                      appId: appId);
                                  setDialogState(() {
                                    isVerifyingDeriv = false;
                                    derivVerifyOk = true;
                                    accountNumController.text =
                                        (info['loginid'] ?? '').toString();
                                    balanceController.text =
                                        ((info['balance'] ?? 0) as num)
                                            .toDouble()
                                            .toStringAsFixed(2);
                                    final c =
                                        (info['currency'] ?? 'USD').toString();
                                    if ([
                                      'USD',
                                      'EUR',
                                      'GBP',
                                      'AUD',
                                      'CAD',
                                      'JPY'
                                    ].contains(c)) {
                                      currency = c;
                                    }
                                    platform = (info['recommended_platform'] ??
                                            platform)
                                        .toString();
                                    brokerController.text =
                                        'Deriv Native WS API';
                                    serverController.text =
                                        'ws.derivws.com (AppID: $appId)';
                                    derivVerifyStatus =
                                        'Verified ${(info['is_virtual'] == true) ? "DEMO" : "REAL LIVE"} account ${info['loginid']} • Balance: ${info['balance']} ${info['currency']}';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isVerifyingDeriv = false;
                                    derivVerifyOk = false;
                                    derivVerifyStatus =
                                        'Verification failed: $e';
                                  });
                                }
                              },
                      ),
                    ),
                    if (derivVerifyStatus != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (derivVerifyOk
                                  ? AppColors.bullishGreen
                                  : AppColors.bearishRed)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: derivVerifyOk
                                ? AppColors.bullishGreen
                                : AppColors.bearishRed,
                          ),
                        ),
                        child: Text(
                          derivVerifyStatus!,
                          style: TextStyle(
                            color: derivVerifyOk
                                ? AppColors.bullishGreen
                                : AppColors.bearishRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    controller: accountNumController,
                    keyboardType:
                        isDerivApi ? TextInputType.text : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isDerivApi
                          ? 'Deriv Account ID (CR / VRTC)'
                          : 'Account Login / ID',
                      hintText:
                          isDerivApi ? 'e.g. VRTC123456 or CR987654' : 'e.g. 202477407',
                      prefixIcon:
                          const Icon(Icons.person, color: AppColors.binanceGold, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brokerController,
                          decoration: const InputDecoration(
                              labelText: 'Broker',
                              hintText: 'Deriv (SVG) LLC'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: serverController,
                          decoration: const InputDecoration(
                              labelText: 'Server',
                              hintText: 'Deriv-Demo'),
                        ),
                      ),
                    ],
                  ),
                  if (!isDerivApi) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Account Password',
                        hintText: 'Master or Investor Password',
                        prefixIcon:
                            Icon(Icons.lock, color: AppColors.binanceGold, size: 20),
                        helperText:
                            'Encrypted at rest with AES-256.',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: balanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Balance / Equity', prefixText: '\$ '),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('currency_$currency'),
                          isExpanded: true,
                          menuMaxHeight: 240,
                          initialValue: currency,
                          decoration:
                              const InputDecoration(labelText: 'Currency'),
                          dropdownColor: AppColors.surface,
                          items: ['USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY']
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => currency = val!),
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
                        color: AppColors.binanceGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.binanceGold),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber,
                                  color: AppColors.binanceGold, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LIVE CAPITAL WARNING',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.binanceGold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You are connecting a LIVE real-money broker account. Orders executed will risk actual capital. '
                            'The Smart Risk Guardian will enforce lot sizing and daily loss limits.',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: isLiveAuthorized,
                                activeColor: AppColors.binanceGold,
                                checkColor: Colors.black,
                                onChanged: (val) => setDialogState(
                                    () => isLiveAuthorized = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'I authorize live broker execution with Risk Guardian active.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold),
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
              child: const Text('CANCEL',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLive ? AppColors.binanceGold : AppColors.bullishGreen,
                foregroundColor: const Color(0xFF0B0E11),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (accountNumController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isDerivApi
                                  ? 'Please verify your Deriv token or enter a CR/VRTC Account ID.'
                                  : 'Please enter an account login number.')),
                        );
                        return;
                      }

                      if (isDerivApi && passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter your Deriv API Token.')),
                        );
                        return;
                      }

                      if (isLive && !isLiveAuthorized) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please check the live authorization box to confirm real capital connection.'),
                            backgroundColor: AppColors.bearishRed,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        final appId = derivAppIdController.text.trim().isEmpty
                            ? '1089'
                            : derivAppIdController.text.trim();
                        final credentialPayload = isDerivApi
                            ? jsonEncode({
                                'api_token': passwordController.text.trim(),
                                'app_id': appId,
                              })
                            : passwordController.text;

                        await apiService.addAccount({
                          'account_number': accountNumController.text.trim(),
                          'broker_name': brokerController.text.trim(),
                          'server': serverController.text.trim(),
                          'platform': platform,
                          'currency': currency,
                          'password': credentialPayload,
                          'balance': double.tryParse(balanceController.text) ??
                              10000.0,
                          'is_auto_trading_enabled':
                              isLive ? isLiveAuthorized : true,
                          'is_authorized_live': isLiveAuthorized,
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          await Provider.of<AccountProvider>(context,
                                  listen: false)
                              .loadAccounts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '$platform account #${accountNumController.text} connected!'),
                              backgroundColor: AppColors.bullishGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Connection error: $e'),
                                backgroundColor: AppColors.bearishRed),
                          );
                        }
                      }
                    },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isLive ? 'CONNECT LIVE ACCOUNT' : 'CONNECT DEMO ACCOUNT',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

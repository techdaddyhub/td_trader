// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Application Settings & PC Connection Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/techdaddy_logo.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _serverController;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveConnection() async {
    final inputUrl = _serverController.text.trim();
    if (inputUrl.isEmpty) {
      setState(() {
        _testResult = 'Please enter a valid PC host or server URL.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final res = await apiService.checkHealth(inputUrl);
      stopwatch.stop();

      await AppConfig.setBaseUrl(inputUrl);

      if (!mounted) return;
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);
      final scannerProvider =
          Provider.of<ScannerProvider>(context, listen: false);

      await Future.wait([
        accountProvider.loadAccounts(),
        scannerProvider.fetchOpportunities(),
      ]);

      if (!mounted) return;
      final bridgeCount = accountProvider.onlineBridgeCount;
      setState(() {
        _isTesting = false;
        _isSuccess = true;
        _testResult =
            'Connected to PC Server! Latency: ${stopwatch.elapsedMilliseconds}ms\n'
            'Owner: ${res['owner'] ?? 'TechDaddy'} | Version: ${res['version'] ?? '2.0.0'}\n'
            'MT4/MT5 EA Terminals Online: $bridgeCount | Accounts Loaded: ${accountProvider.accounts.length}';
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _isSuccess = false;
        _testResult = 'Connection Failed (${e.toString()}).\n'
            'Ensure your PC is running the TD Trader server and both devices are on the same Wi-Fi.';
      });
    }
  }

  void _applyPreset(String presetUrl) {
    _serverController.text = presetUrl;
    _testAndSaveConnection();
  }

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & PC CONNECTION'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. PC & TRADING SERVER CONNECTION CARD
          _buildSectionHeader('CONNECT ANDROID TO PC / SERVER'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.binanceGold, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.computer,
                          color: AppColors.binanceGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Trading Server / PC Host IP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your computer’s local IP address or VPS URL to sync market signals and MetaTrader 4/5 broker execution:',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Server Host URL',
                      hintText: 'http://192.168.1.50:8000',
                      prefixIcon:
                          const Icon(Icons.link, color: AppColors.binanceGold),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: () => _serverController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        backgroundColor: AppColors.surfaceLight,
                        avatar: const Icon(Icons.wifi,
                            size: 16, color: AppColors.binanceGold),
                        label: const Text('Local Wi-Fi PC',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textPrimary)),
                        onPressed: () =>
                            _applyPreset('http://192.168.1.100:8000'),
                      ),
                      ActionChip(
                        backgroundColor: AppColors.surfaceLight,
                        avatar: const Icon(Icons.laptop,
                            size: 16, color: AppColors.binanceGold),
                        label: const Text('Localhost (Same PC)',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textPrimary)),
                        onPressed: () => _applyPreset('http://127.0.0.1:8000'),
                      ),
                      ActionChip(
                        backgroundColor: AppColors.surfaceLight,
                        avatar: const Icon(Icons.phone_android,
                            size: 16, color: AppColors.binanceGold),
                        label: const Text('Emulator Host',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textPrimary)),
                        onPressed: () => _applyPreset('http://10.0.2.2:8000'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.binanceGold,
                        foregroundColor: const Color(0xFF0B0E11),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isTesting ? null : _testAndSaveConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.electrical_services, size: 20),
                      label: Text(
                        _isTesting
                            ? 'TESTING CONNECTION...'
                            : 'TEST & CONNECT TO PC',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? AppColors.bullishGreen.withValues(alpha: 0.12)
                            : AppColors.bearishRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess
                              ? AppColors.bullishGreen
                              : AppColors.bearishRed,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess
                                ? AppColors.bullishGreen
                                : AppColors.bearishRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                color: _isSuccess
                                    ? AppColors.bullishGreen
                                    : AppColors.bearishRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. QUICK 3-STEP PC CONNECTION GUIDE
          Card(
            color: AppColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              initiallyExpanded: false,
              leading:
                  const Icon(Icons.help_outline, color: AppColors.binanceGold),
              title: const Text(
                'How to Connect Android to Your PC in 3 Steps',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Find PC Local IP:',
                          style: TextStyle(
                              color: AppColors.binanceGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Text(
                          'On your Windows PC, press Win+R, type "cmd", then type "ipconfig". Note the IPv4 Address (e.g. 192.168.1.50).',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                      SizedBox(height: 8),
                      Text('2. Connect to Same Wi-Fi:',
                          style: TextStyle(
                              color: AppColors.binanceGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Text(
                          'Ensure your Android device is on the same local Wi-Fi router network as your computer.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                      SizedBox(height: 8),
                      Text('3. Start TD Trader Backend & Test:',
                          style: TextStyle(
                              color: AppColors.binanceGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Text(
                          'Launch the backend on PC, enter "http://<YOUR_PC_IP>:8000" above, and tap "TEST & CONNECT TO PC".',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. VOICE ASSISTANT SETTINGS
          _buildSectionHeader('TD AI VOICE CONFIGURATION'),
          Card(
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: voice.selectedPersonality,
                    decoration:
                        const InputDecoration(labelText: 'Voice Personality'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Aria_Fintech_Pro',
                          child: Text('Aria (Female Fintech Lead)')),
                      DropdownMenuItem(
                          value: 'Sophia_Macro_Strategist',
                          child: Text('Sophia (Global Macro)')),
                      DropdownMenuItem(
                          value: 'Marcus_Quant_Lead',
                          child: Text('Marcus (Male Quant Lead)')),
                      DropdownMenuItem(
                          value: 'Alexander_Institutional',
                          child: Text('Alexander (Risk Arbiter)')),
                    ],
                    onChanged: (val) => voice.setPersonality(val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Speech Speed:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text('${voice.speechSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.binanceGold)),
                    ],
                  ),
                  Slider(
                    value: voice.speechSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: AppColors.binanceGold,
                    onChanged: (val) => voice.setSpeed(val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Volume:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text('${(voice.volume * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.binanceGold)),
                    ],
                  ),
                  Slider(
                    value: voice.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: AppColors.binanceGold,
                    onChanged: (val) => voice.setVolume(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. SECURITY & ENCRYPTION STATUS
          _buildSectionHeader('CYBERSECURITY & ENCRYPTION'),
          Card(
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSecurityRow('Broker Credential Storage',
                      'AES-256 Fernet Encrypted', AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow(
                      'User Password Hashing',
                      'PBKDF2-HMAC-SHA256 (600k rounds)',
                      AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow('API Token Standard',
                      'RFC 7519 HMAC-SHA256 JWT', AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow(
                      'Account Isolation',
                      'Strict Zero-Commingling Enforced',
                      AppColors.binanceGold),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. ABOUT & TECHDADDY OWNERSHIP
          _buildSectionHeader('OWNERSHIP & LEGAL NOTICES'),
          Card(
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  TechDaddyLogo(size: 64, showText: true, showCopyright: true),
                  SizedBox(height: 12),
                  Text(
                    'Exclusive Property of TechDaddy Fintech Systems',
                    style: TextStyle(
                        color: AppColors.binanceGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All algorithms, neural network architectures, Smart Risk Guardian rules, and MetaTrader bridge protocols are protected under international copyright law.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.binanceGold,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

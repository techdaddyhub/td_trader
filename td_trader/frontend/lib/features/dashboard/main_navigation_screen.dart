// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Main Adaptive Navigation Shell with Navigation Drawer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/widgets/techdaddy_logo.dart';
import '../market_scanner/scanner_screen.dart';
import '../voice_assistant/voice_assistant_screen.dart';
import '../risk_guardian/risk_guardian_screen.dart';
import '../backtesting/backtest_screen.dart';
import '../account_manager/account_manager_screen.dart';
import '../trading/trading_terminal_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../trading_journal/journal_screen.dart';
import '../settings/settings_screen.dart';
import '../authentication/auth_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _mainScreens = const [
    MarketScannerScreen(),
    TradingTerminalScreen(),
    VoiceAssistantScreen(),
    RiskGuardianScreen(),
    StrategyBacktesterScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AccountProvider>(context, listen: false).loadAccounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final isOnline = accountProvider.isServerOnline;
    final bridgeCount = accountProvider.onlineBridgeCount;
    final isCloud = AppConfig.baseUrl.contains('railway.app') ||
        AppConfig.baseUrl.startsWith('https://');
    final badgeColor =
        isOnline ? AppColors.bullishGreen : AppColors.binanceGold;
    final badgeText = isOnline
        ? (isCloud
            ? (bridgeCount > 0 ? 'CLOUD ($bridgeCount EA)' : 'CLOUD ONLINE')
            : (bridgeCount > 0 ? 'PC ONLINE ($bridgeCount EA)' : 'PC ONLINE'))
        : (isCloud ? 'CONNECT CLOUD' : 'CONNECT PC');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: Row(
          children: [
            const TechDaddyLogo(size: 32, showText: false),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TD TRADER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: AppColors.binanceGold,
                      ),
                    ),
                  ),
                  Text(
                    'AI ECOSYSTEM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 8.5,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Quick Connect PC / Broker Status Badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isOnline ? Icons.cloud_done : Icons.wifi,
                        size: 14, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Prominent Gear Icon for Settings & PC Connection
          IconButton(
            icon: const Icon(Icons.settings,
                color: AppColors.binanceGold, size: 26),
            tooltip: 'Settings & Connect PC/Broker',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.surfaceLight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: const [
                      TechDaddyLogo(size: 46, showText: false),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TECHDADDY',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.5,
                                color: AppColors.primaryCyan),
                          ),
                          Text(
                            'TD TRADER v2.0.0',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Trade Smarter. Think Faster. Let AI Explain.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Copyright © 2026 TechDaddy',
                    style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.radar, color: AppColors.primaryCyan),
              title: const Text('AI Market Scanner'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange,
                  color: AppColors.bullishGreen),
              title: const Text('Trading Terminal'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over,
                  color: AppColors.primaryCyan),
              title: const Text('TD AI Voice Analyst'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield, color: AppColors.warningAmber),
              title: const Text('Smart Risk Guardian'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.science, color: AppColors.goldAccent),
              title: const Text('Strategy Lab & Backtest'),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(color: AppColors.border),
            ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
              title: const Text('Multi-Account Manager'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountManagerScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.pie_chart, color: AppColors.primaryCyan),
              title: const Text('Portfolio & Exposure'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PortfolioScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.auto_stories, color: AppColors.goldAccent),
              title: const Text('AI Trading Journal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TradingJournalScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.settings, color: AppColors.textSecondary),
              title: const Text('Settings & Presets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.bearishRed),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.bearishRed)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _mainScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radar),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Terminal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'TD Voice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Risk Guard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Strategy',
          ),
        ],
      ),
    );
  }
}

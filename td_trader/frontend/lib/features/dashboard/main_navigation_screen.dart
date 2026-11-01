// TD TRADER - Main Adaptive Navigation Shell with Navigation Drawer
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Icon(Icons.show_chart, color: AppColors.primaryCyan, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'TD TRADER',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Trade Smarter. Think Faster. Let AI Explain.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
              leading: const Icon(Icons.currency_exchange, color: AppColors.bullishGreen),
              title: const Text('Trading Terminal'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over, color: AppColors.primaryCyan),
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
              leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
              title: const Text('Multi-Account Manager'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart, color: AppColors.primaryCyan),
              title: const Text('Portfolio & Exposure'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories, color: AppColors.goldAccent),
              title: const Text('AI Trading Journal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TradingJournalScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.textSecondary),
              title: const Text('Settings & Presets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.bearishRed),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.bearishRed)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
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

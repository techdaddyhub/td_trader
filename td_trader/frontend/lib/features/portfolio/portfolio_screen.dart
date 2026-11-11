// TD TRADER - Portfolio Exposure & Aggregator Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Map<String, dynamic>? _portfolioData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPortfolio();
  }

  Future<void> _fetchPortfolio() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await apiService.getAccounts();
      double totalBal = 0.0;
      double totalEq = 0.0;
      double totalFloating = 0.0;
      int activeCount = 0;

      for (var a in accounts) {
        totalBal += a.balance;
        totalEq += a.equity;
        totalFloating += a.floatingPnl;
        if (a.connectionStatus == 'CONNECTED') activeCount++;
      }

      setState(() {
        _portfolioData = {
          'total_accounts': accounts.length,
          'active_connections': activeCount,
          'total_balance': totalBal,
          'total_equity': totalEq,
          'total_floating_pnl': totalFloating,
          'accounts': accounts,
        };
      });
    } catch (e) {
      debugPrint('Error loading portfolio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PORTFOLIO & RISK EXPOSURE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
            onPressed: _fetchPortfolio,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _portfolioData == null
              ? const Center(child: Text('Portfolio data unavailable.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Account Isolation Safeguard Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.verified_user,
                              color: AppColors.primaryCyan, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'FINTECH ISOLATION SAFEGUARD: Portfolio metrics provide analytical aggregation only. Capital is strictly ring-fenced per broker account without pooling.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Portfolio High-Level Statistics
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryCard(
                                'TOTAL BALANCE',
                                '\$${_portfolioData!['total_balance'].toStringAsFixed(2)}',
                                AppColors.textPrimary)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCard(
                                'TOTAL EQUITY',
                                '\$${_portfolioData!['total_equity'].toStringAsFixed(2)}',
                                AppColors.primaryCyan)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'FLOATING PnL',
                            '\$${_portfolioData!['total_floating_pnl'].toStringAsFixed(2)}',
                            _portfolioData!['total_floating_pnl'] >= 0
                                ? AppColors.bullishGreen
                                : AppColors.bearishRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Market Category Exposure Breakdown
                    const Text('ASSET CLASS ALLOCATION & EXPOSURE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildExposureBar(
                              'Forex Markets', 0.35, AppColors.primaryCyan),
                          const SizedBox(height: 12),
                          _buildExposureBar('Deriv Synthetics (V75 / Boom / Crash)',
                              0.25, AppColors.binanceGold),
                          const SizedBox(height: 12),
                          _buildExposureBar('Precious Metals (Gold/Silver)',
                              0.20, AppColors.goldAccent),
                          const SizedBox(height: 12),
                          _buildExposureBar(
                              'Cryptocurrency', 0.12, AppColors.bullishGreen),
                          const SizedBox(height: 12),
                          _buildExposureBar('Indices & Commodities', 0.08,
                              AppColors.warningAmber),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Connected Accounts List
                    const Text('CONNECTED BROKER ACCOUNTS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    ...(_portfolioData!['accounts'] as List).map((acct) {
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                              '${acct.brokerName} (#${acct.accountNumber})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${acct.platform.replaceAll("_", " ")} • Free Margin: \$${acct.freeMargin.toStringAsFixed(2)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${acct.equity.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryCyan)),
                              Text(
                                acct.isAutoTradingEnabled
                                    ? 'Auto ON'
                                    : 'Auto OFF',
                                style: TextStyle(
                                  color: acct.isAutoTradingEnabled
                                      ? AppColors.bullishGreen
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildExposureBar(String title, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
            Text('${(fraction * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: fraction,
          backgroundColor: AppColors.surfaceLight,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

// MODULE 3: SMART RISK GUARDIAN SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/widgets/common_widgets.dart';

class RiskGuardianScreen extends StatefulWidget {
  const RiskGuardianScreen({super.key});

  @override
  State<RiskGuardianScreen> createState() => _RiskGuardianScreenState();
}

class _RiskGuardianScreenState extends State<RiskGuardianScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acct = Provider.of<AccountProvider>(context, listen: false).activeAccount;
      if (acct != null) {
        Provider.of<RiskProvider>(context, listen: false).fetchConfig(acct.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final risk = Provider.of<RiskProvider>(context);
    final account = Provider.of<AccountProvider>(context);
    final activeAcct = account.activeAccount;
    final cfg = risk.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMART RISK GUARDIAN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
            onPressed: () {
              if (activeAcct != null) risk.fetchConfig(activeAcct.id);
            },
          ),
        ],
      ),
      body: activeAcct == null
          ? const Center(child: Text('No active trading account selected.'))
          : risk.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
              : cfg == null
                  ? const Center(child: Text('Risk configuration unavailable.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Breach Banner if Tripped
                        if (cfg.isRiskGuardianTripped)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bearishRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.bearishRed),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: AppColors.bearishRed, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RISK GUARDIAN TRIPPED - AUTO-ENTRIES SUSPENDED',
                                        style: TextStyle(color: AppColors.bearishRed, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cfg.tripReason ?? 'Risk threshold breach detected.',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Emergency Control Panel
                        EmergencyControlPanel(
                          accountId: activeAcct.id,
                          onAction: (act, confirm) async {
                            try {
                              await risk.triggerEmergency(activeAcct.id, act, confirm);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Emergency Action Executed: $act')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Action Failed: $e'), backgroundColor: AppColors.bearishRed),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Risk Dashboard Metrics Grid
                        const Text(
                          'MANDATORY RISK PARAMETERS (16 INDEPENDENT GATES)',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.4,
                          children: [
                            _buildRiskCard('Risk Per Trade', '${cfg.riskPerTradePct}%', 'Automatic Sizing'),
                            _buildRiskCard('Max Daily Loss', '\$${cfg.maxDailyLossAmount}', '${cfg.maxDailyLossPct}% cap'),
                            _buildRiskCard('Max Daily Drawdown', '${cfg.maxDailyDrawdownPct}%', 'Trailing Equity'),
                            _buildRiskCard('Max Account Drawdown', '${cfg.maxAccountDrawdownPct}%', 'Hard Equity Floor'),
                            _buildRiskCard('Max Open Trades', '${cfg.maxOpenTrades}', 'Concurrent limit'),
                            _buildRiskCard('Max Correlated Exposure', '${cfg.maxCorrelatedExposure}', 'Currency cluster cap'),
                            _buildRiskCard('Max Lot Size', '${cfg.maxLotSize} Lots', 'Single ticket limit'),
                            _buildRiskCard('Consecutive Losses', '${cfg.currentConsecutiveLosses} / ${cfg.consecutiveLossLimit}', 'Cooldown lockout'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Account Live Health Card
                        Card(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Account #${activeAcct.accountNumber} (${activeAcct.brokerName})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: activeAcct.isAutoTradingEnabled ? AppColors.bullishGreen : AppColors.warningAmber,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        activeAcct.isAutoTradingEnabled ? 'AUTO TRADING ON' : 'AUTO TRADING PAUSED',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppColors.border, height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMetric('Balance', '\$${activeAcct.balance.toStringAsFixed(2)}'),
                                    _buildMetric('Equity', '\$${activeAcct.equity.toStringAsFixed(2)}'),
                                    _buildMetric('Free Margin', '\$${activeAcct.freeMargin.toStringAsFixed(2)}'),
                                    _buildMetric('Floating PnL', '\$${activeAcct.floatingPnl.toStringAsFixed(2)}', color: activeAcct.floatingPnl >= 0 ? AppColors.bullishGreen : AppColors.bearishRed),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildRiskCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}


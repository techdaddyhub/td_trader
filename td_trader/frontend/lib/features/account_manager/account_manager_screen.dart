// MODULE 5: MULTI-ACCOUNT MANAGER & METATRADER BRIDGE SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/widgets/connect_account_dialog.dart';

class AccountManagerScreen extends StatefulWidget {
  const AccountManagerScreen({super.key});

  @override
  State<AccountManagerScreen> createState() => _AccountManagerScreenState();
}

class _AccountManagerScreenState extends State<AccountManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    });
  }

  void _showAddAccountDialog(BuildContext context) {
    showConnectMetaTraderDialog(context);
  }

  void _showLiveAuthorizationDialog(
      BuildContext context, TradingAccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('EXPLICIT LIVE CAPITAL AUTHORIZATION',
            style: TextStyle(color: AppColors.warningAmber, fontSize: 16)),
        content: Text(
          'You are authorizing live automated trading for account #${account.accountNumber} (${account.brokerName}).\n\n'
          'Mandatory Fintech Notice: Real capital will be subjected to automated execution. '
          'Smart Risk Guardian will strictly enforce your risk gates.\n\n'
          'Do you explicitly authorize live automated trading?',
          style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DECLINE',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningAmber),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AccountProvider>(context, listen: false)
                  .authorizeLive(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Live trading explicitly authorized for this account.')),
              );
            },
            child: const Text('EXPLICITLY AUTHORIZE',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'MULTI-ACCOUNT MANAGER',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primaryCyan),
            onPressed: () => _showAddAccountDialog(context),
            tooltip: 'Connect Broker (Deriv / MT4 / MT5)',
          ),
        ],
      ),
      body: accountProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Isolation Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_outline,
                          size: 16, color: AppColors.primaryCyan),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Strict Account Isolation Engaged: Balances are never commingled. Each account executes with independent credentials and dedicated risk gates.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Accounts List
                ...accountProvider.accounts.map((acct) {
                  final isActive = accountProvider.activeAccount?.id == acct.id;
                  final isLive = acct.platform.contains('LIVE');

                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: isActive
                              ? AppColors.primaryCyan
                              : AppColors.border,
                          width: isActive ? 1.5 : 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isLive
                                    ? Icons.account_balance
                                    : Icons.analytics_outlined,
                                color: isLive
                                    ? AppColors.warningAmber
                                    : AppColors.primaryCyan,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${acct.accountNumber} • ${acct.platform.replaceAll("_", " ")}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      acct.brokerName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCyan
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.primaryCyan),
                                  ),
                                  child: const Text('ACTIVE',
                                      style: TextStyle(
                                          color: AppColors.primaryCyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                )
                              else
                                TextButton(
                                  onPressed: () =>
                                      accountProvider.switchActiveAccount(acct),
                                  child: const Text('SELECT',
                                      style: TextStyle(
                                          color: AppColors.primaryCyan,
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                          const Divider(color: AppColors.border, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric('Balance',
                                  '\$${acct.balance.toStringAsFixed(2)}'),
                              _buildMetric('Equity',
                                  '\$${acct.equity.toStringAsFixed(2)}'),
                              _buildMetric('Free Margin',
                                  '\$${acct.freeMargin.toStringAsFixed(2)}'),
                              _buildMetric('Floating PnL',
                                  '\$${acct.floatingPnl.toStringAsFixed(2)}',
                                  color: acct.floatingPnl >= 0
                                      ? AppColors.bullishGreen
                                      : AppColors.bearishRed),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Auto-trading toggle
                              Row(
                                children: [
                                  Switch(
                                    value: acct.isAutoTradingEnabled,
                                    activeThumbColor: AppColors.bullishGreen,
                                    onChanged: (val) {
                                      if (isLive &&
                                          val &&
                                          !acct.isAuthorizedLive) {
                                        _showLiveAuthorizationDialog(
                                            context, acct);
                                      } else {
                                        accountProvider.toggleAutoTrading(val);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    acct.isAutoTradingEnabled
                                        ? 'Auto Trading ON'
                                        : 'Auto Trading OFF',
                                    style: TextStyle(
                                      color: acct.isAutoTradingEnabled
                                          ? AppColors.bullishGreen
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (isLive && !acct.isAuthorizedLive)
                                TextButton.icon(
                                  icon: const Icon(Icons.security,
                                      size: 14, color: AppColors.warningAmber),
                                  label: const Text('AUTHORIZE LIVE',
                                      style: TextStyle(
                                          color: AppColors.warningAmber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  onPressed: () => _showLiveAuthorizationDialog(
                                      context, acct),
                                ),
                            ],
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

  Widget _buildMetric(String label, String val, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(val,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

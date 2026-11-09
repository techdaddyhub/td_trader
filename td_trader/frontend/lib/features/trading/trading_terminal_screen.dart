// TD TRADER - Unified Trading Terminal Screen with Advanced MT4/MT5 Integration
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/connect_account_dialog.dart';

class TradingTerminalScreen extends StatefulWidget {
  const TradingTerminalScreen({super.key});

  @override
  State<TradingTerminalScreen> createState() => _TradingTerminalScreenState();
}

class _TradingTerminalScreenState extends State<TradingTerminalScreen> {
  String _selectedSymbol = 'XAUUSD';
  final _lotsController = TextEditingController(text: '0.10');
  final _slController = TextEditingController(text: '2730.00');
  final _tpController = TextEditingController(text: '2770.00');
  bool _isExecuting = false;

  final List<String> _symbols = [
    'XAUUSD',
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'BTCUSD',
    'ETHUSD',
    'US30',
    'UKOIL'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    });
  }

  @override
  void dispose() {
    _lotsController.dispose();
    _slController.dispose();
    _tpController.dispose();
    super.dispose();
  }

  Future<void> _submitTrade(String direction) async {
    final account = Provider.of<AccountProvider>(context, listen: false).activeAccount;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect or select an active trading account first.')),
      );
      showConnectMetaTraderDialog(context);
      return;
    }

    setState(() => _isExecuting = true);

    try {
      await apiService.executeTrade({
        'account_id': account.id,
        'instrument': _selectedSymbol,
        'direction': direction,
        'lots': double.tryParse(_lotsController.text) ?? 0.1,
        'stop_loss': double.tryParse(_slController.text) ?? 0.0,
        'take_profit': double.tryParse(_tpController.text) ?? 0.0,
        'order_type': direction,
      });

      if (mounted) {
        Provider.of<AccountProvider>(context, listen: false).loadPositions(account.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$direction order on $_selectedSymbol executed on ${account.platform} (${account.accountNumber})!'),
            backgroundColor: direction == 'BUY' ? AppColors.bullishGreen : AppColors.bearishRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Execution Blocked: $e'), backgroundColor: AppColors.bearishRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  Future<void> _createInstantPaperAccount() async {
    try {
      await apiService.addAccount({
        'account_number': 'DEMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'broker_name': 'TechDaddy Simulator',
        'server': 'TD-Paper-Server',
        'platform': 'PAPER_TRADING',
        'currency': 'USD',
        'balance': 10000.0,
        'is_auto_trading_enabled': true,
        'is_authorized_live': false,
      });
      if (mounted) {
        await Provider.of<AccountProvider>(context, listen: false).loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instant $10,000 Paper Trading Demo Account activated!'),
            backgroundColor: AppColors.bullishGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.bearishRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final activeAcct = accountProvider.activeAccount;
    final allAccounts = accountProvider.accounts;
    final positions = accountProvider.positions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRADING TERMINAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link, color: AppColors.binanceGold),
            tooltip: 'Connect MetaTrader Account',
            onPressed: () => showConnectMetaTraderDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. ACTIVE ACCOUNT SELECTOR & BROKER STATUS BAR
          if (activeAcct != null) ...[
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: activeAcct.platform.contains('LIVE')
                      ? AppColors.binanceGold
                      : AppColors.bullishGreen,
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          activeAcct.platform.contains('LIVE') ? Icons.bolt : Icons.science,
                          color: activeAcct.platform.contains('LIVE')
                              ? AppColors.binanceGold
                              : AppColors.bullishGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int>(
                            value: activeAcct.id,
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            items: allAccounts.map((a) {
                              final isLive = a.platform.contains('LIVE');
                              return DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(
                                  '${isLive ? "⚡ [LIVE]" : "🟢 [DEMO]"} ${a.platform} #${a.accountNumber} (${a.brokerName})',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLive ? AppColors.binanceGold : AppColors.bullishGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final selected = allAccounts.firstWhere((a) => a.id == id);
                                accountProvider.switchActiveAccount(selected);
                              }
                            },
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => showConnectMetaTraderDialog(context),
                          icon: const Icon(Icons.add, size: 16, color: AppColors.binanceGold),
                          label: const Text('ADD', style: TextStyle(color: AppColors.binanceGold, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Balance', '\$${activeAcct.balance.toStringAsFixed(2)}', AppColors.textPrimary),
                        _buildMetricCol('Equity', '\$${activeAcct.equity.toStringAsFixed(2)}', AppColors.binanceGold),
                        _buildMetricCol('Free Margin', '\$${activeAcct.freeMargin.toStringAsFixed(2)}', AppColors.bullishGreen),
                        _buildMetricCol('Server', activeAcct.server, AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // ZERO ACCOUNTS CONNECTED WELCOME CARD
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.binanceGold, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.hub, size: 48, color: AppColors.binanceGold),
                    const SizedBox(height: 12),
                    const Text(
                      'CONNECT METATRADER 4 & 5 ACCOUNTS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.binanceGold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Link your live or demo MT4/MT5 trading account (IC Markets, FTMO, Exness, Pepperstone, etc.) with encrypted zero-latency execution.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.binanceGold,
                              foregroundColor: const Color(0xFF0B0E11),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text('CONNECT MT4 / MT5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => showConnectMetaTraderDialog(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.binanceGold,
                              side: const BorderSide(color: AppColors.binanceGold),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.play_circle_outline, size: 18),
                            label: const Text('PAPER DEMO (\$10K)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: _createInstantPaperAccount,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. LIVE ORDER TICKET CARD
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _selectedSymbol,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        underline: const SizedBox(),
                        items: _symbols.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedSymbol = val!),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.binanceGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.binanceGold.withOpacity(0.4)),
                        ),
                        child: Text(
                          activeAcct != null ? '${activeAcct.platform.replaceAll("_", " ")} ACTIVE' : 'NO ACCOUNT',
                          style: const TextStyle(color: AppColors.binanceGold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lotsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Lots (Volume)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _slController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Stop Loss'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _tpController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Take Profit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bullishGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isExecuting ? null : () => _submitTrade('BUY'),
                          child: const Text('BUY / LONG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bearishRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isExecuting ? null : () => _submitTrade('SELL'),
                          child: const Text('SELL / SHORT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. OPEN POSITIONS & AUDIT TABLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OPEN POSITIONS & BROKER TICKETS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.binanceGold, letterSpacing: 0.8),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  if (activeAcct != null) {
                    accountProvider.loadPositions(activeAcct.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (positions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  activeAcct == null
                      ? 'Connect an MT4/MT5 account above to view live broker positions.'
                      : 'No open positions on ${activeAcct.platform} #${activeAcct.accountNumber}.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...positions.map((pos) => Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pos.direction == 'BUY'
                            ? AppColors.bullishGreen.withOpacity(0.15)
                            : AppColors.bearishRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pos.direction,
                        style: TextStyle(
                          color: pos.direction == 'BUY' ? AppColors.bullishGreen : AppColors.bearishRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('${pos.instrument} - ${pos.lots.toStringAsFixed(2)} Lots', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Entry: ${pos.entryPrice} | SL: ${pos.stopLoss} | TP: ${pos.takeProfit}'),
                    trailing: Text(
                      '${pos.floatingPnl >= 0 ? "+" : ""}\$${pos.floatingPnl.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: pos.floatingPnl >= 0 ? AppColors.bullishGreen : AppColors.bearishRed,
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

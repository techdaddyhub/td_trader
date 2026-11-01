// TD TRADER - Unified Trading Terminal Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/services/api_service.dart';

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
        const SnackBar(content: Text('Please select an active trading account first.')),
      );
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
            content: Text('$direction order on $_selectedSymbol executed and confirmed!'),
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

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final activeAcct = accountProvider.activeAccount;
    final positions = accountProvider.positions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRADING TERMINAL'),
        actions: [
          if (activeAcct != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${activeAcct.platform.replaceAll("_", " ")}: \$${activeAcct.equity.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: activeAcct == null
          ? const Center(child: Text('No active account selected.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live Order Ticket Card
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Smart Risk Gates: Active', style: TextStyle(color: AppColors.primaryCyan, fontSize: 11)),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_upward, color: Colors.black),
                                label: const Text('BUY MARKET'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bullishGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _isExecuting ? null : () => _submitTrade('BUY'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_downward, color: Colors.white),
                                label: const Text('SELL MARKET'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bearishRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _isExecuting ? null : () => _submitTrade('SELL'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Open Positions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OPEN POSITIONS (${positions.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primaryCyan, size: 20),
                      onPressed: () => accountProvider.loadPositions(activeAcct.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (positions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('No active open positions on this account.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...positions.map((p) {
                    final isBuy = p.direction == 'BUY';
                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: p.floatingPnl >= 0 ? AppColors.bullishGreen.withOpacity(0.3) : AppColors.bearishRed.withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isBuy ? AppColors.bullishGreen : AppColors.bearishRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.direction,
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${p.instrument} (${p.lots} lots)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Open: ${p.openPrice} • Current: ${p.currentPrice}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '\$${p.floatingPnl.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: p.floatingPnl >= 0 ? AppColors.bullishGreen : AppColors.bearishRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.bearishRed),
                                  tooltip: 'Close position',
                                  onPressed: () => accountProvider.closePosition(p.id),
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
}


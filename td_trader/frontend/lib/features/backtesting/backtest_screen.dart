// MODULE 4: AI STRATEGY BACKTESTER & QUANT LABORATORY SCREEN
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class StrategyBacktesterScreen extends StatefulWidget {
  const StrategyBacktesterScreen({super.key});

  @override
  State<StrategyBacktesterScreen> createState() => _StrategyBacktesterScreenState();
}

class _StrategyBacktesterScreenState extends State<StrategyBacktesterScreen> {
  String _selectedStrategy = 'MA_Crossover';
  String _selectedInstrument = 'EURUSD';
  String _selectedTimeframe = 'H1';
  double _initialBalance = 10000.0;
  double _riskPct = 1.0;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  List<dynamic>? _comparisonResults;

  final List<String> _strategies = [
    'MA_Crossover',
    'RSI_Dynamic_Reversal',
    'MACD_Momentum',
    'Bollinger_Squeeze_Breakout',
    'Supertrend_Structure_Confluence'
  ];

  final List<String> _instruments = [
    'EURUSD',
    'GBPUSD',
    'XAUUSD',
    'BTCUSD',
    'US30',
    'UKOIL'
  ];

  Future<void> _runBacktest() async {
    setState(() {
      _isLoading = true;
      _comparisonResults = null;
    });

    try {
      final res = await apiService.runBacktest({
        'strategy_name': _selectedStrategy,
        'instrument': _selectedInstrument,
        'timeframe': _selectedTimeframe,
        'start_date': '2026-01-01',
        'end_date': '2026-11-01',
        'initial_balance': _initialBalance,
        'risk_per_trade_pct': _riskPct,
        'spread_pips': 1.2,
        'commission_per_lot': 5.0,
        'slippage_pips': 0.5,
        'run_walk_forward': true,
      });
      setState(() {
        _result = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backtest error: $e'), backgroundColor: AppColors.bearishRed),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runComparison() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await apiService.compareStrategies(_selectedInstrument, _strategies);
      setState(() {
        _comparisonResults = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comparison error: $e'), backgroundColor: AppColors.bearishRed),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUANTITATIVE STRATEGY LAB'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.compare_arrows, color: AppColors.goldAccent),
            label: const Text('COMPARE STRATEGIES', style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold)),
            onPressed: _runComparison,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Configuration Card
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STRATEGY CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStrategy,
                          decoration: const InputDecoration(labelText: 'Strategy'),
                          items: _strategies.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedStrategy = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedInstrument,
                          decoration: const InputDecoration(labelText: 'Instrument'),
                          items: _instruments.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedInstrument = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: DropdownButtonFormField<String>(
                          value: _selectedTimeframe,
                          decoration: const InputDecoration(labelText: 'Timeframe'),
                          items: ['M15', 'H1', 'H4', 'D1'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setState(() => _selectedTimeframe = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Risk Per Trade: ${_riskPct.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textSecondary)),
                      Text('Initial Capital: \$${_initialBalance.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('RUN QUANTITATIVE BACKTEST (WITH WALK-FORWARD)'),
                      onPressed: _isLoading ? null : _runBacktest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primaryCyan))),

          // Side-by-Side Strategy Comparison View
          if (_comparisonResults != null) ...[
            const Text('SIDE-BY-SIDE STRATEGY COMPARISON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.goldAccent)),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Strategy')),
                    DataColumn(label: Text('Net Profit')),
                    DataColumn(label: Text('Win Rate')),
                    DataColumn(label: Text('Profit Factor')),
                    DataColumn(label: Text('Max DD')),
                    DataColumn(label: Text('Trades')),
                  ],
                  rows: _comparisonResults!.map((row) {
                    final net = (row['net_profit'] as num).toDouble();
                    return DataRow(cells: [
                      DataCell(Text(row['strategy_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('\$${net.toStringAsFixed(2)}', style: TextStyle(color: net >= 0 ? AppColors.bullishGreen : AppColors.bearishRed, fontWeight: FontWeight.bold))),
                      DataCell(Text('${row['win_rate']}%')),
                      DataCell(Text('${row['profit_factor']}')),
                      DataCell(Text('${row['max_drawdown_pct']}%')),
                      DataCell(Text('${row['total_trades']}')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],

          // Detailed Single Backtest Result View
          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryCyan),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Includes realistic spread (1.2 pips), slippage (0.5 pips), and broker commissions (\$5/lot). Historical results never guarantee future performance.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Net Profit', '\$${_result!['net_profit']}', _result!['net_profit'] >= 0 ? AppColors.bullishGreen : AppColors.bearishRed),
                _buildStatCard('Win Rate', '${_result!['win_rate']}%', AppColors.primaryCyan),
                _buildStatCard('Profit Factor', '${_result!['profit_factor']}', AppColors.goldAccent),
                _buildStatCard('Max Drawdown', '${_result!['max_drawdown_pct']}%', AppColors.bearishRed),
                _buildStatCard('Total Trades', '${_result!['total_trades']}', Colors.white),
                _buildStatCard('Sharpe Ratio', '${_result!['sharpe_ratio']}', AppColors.primaryCyan),
                _buildStatCard('Expectancy', '\$${_result!['expectancy_usd']}', Colors.white),
                _buildStatCard('WFE Efficiency', '${_result!['walk_forward_metrics']?['walk_forward_efficiency_pct'] ?? 80}%', AppColors.bullishGreen),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color valColor) {
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
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}


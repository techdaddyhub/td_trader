// TD TRADER - AI Strategy Management & Custom Builder Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StrategyLabScreen extends StatefulWidget {
  const StrategyLabScreen({super.key});

  @override
  State<StrategyLabScreen> createState() => _StrategyLabScreenState();
}

class _StrategyLabScreenState extends State<StrategyLabScreen> {
  final List<Map<String, dynamic>> _strategies = [
    {
      'name': 'MA_Crossover',
      'label': 'Moving Average Dynamic Crossover',
      'desc':
          'Fast EMA vs Slow EMA with volatility expansion filtering and ATR trailing stops.',
      'isActive': true,
      'winRate': 64.5,
      'profitFactor': 2.15,
      'trades': 142
    },
    {
      'name': 'RSI_Dynamic_Reversal',
      'label': 'RSI Mean Reversion & Divergence',
      'desc':
          'Dynamic overbought/oversold boundaries scaled by trailing market ATR.',
      'isActive': true,
      'winRate': 58.2,
      'profitFactor': 1.85,
      'trades': 98
    },
    {
      'name': 'MACD_Momentum',
      'label': 'MACD Multi-Timeframe Momentum',
      'desc':
          'Signal line cross with zero-line confirmation and momentum divergence.',
      'isActive': true,
      'winRate': 61.0,
      'profitFactor': 2.05,
      'trades': 116
    },
    {
      'name': 'Bollinger_Squeeze_Breakout',
      'label': 'Bollinger Band Squeeze Breakout',
      'desc':
          'Identifies tight volatility compressions followed by institutional volume expansion.',
      'isActive': false,
      'winRate': 55.4,
      'profitFactor': 1.70,
      'trades': 84
    },
    {
      'name': 'Supertrend_Structure_Confluence',
      'label': 'Supertrend & Market Structure Confluence',
      'desc':
          'Combines trend direction with structural Break of Structure (BOS) continuity.',
      'isActive': true,
      'winRate': 68.3,
      'profitFactor': 2.40,
      'trades': 175
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI STRATEGY MANAGEMENT'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _strategies.length,
        itemBuilder: (ctx, idx) {
          final s = _strategies[idx];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      s['isActive'] ? AppColors.primaryCyan : AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s['label'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Switch(
                        value: s['isActive'],
                        activeThumbColor: AppColors.bullishGreen,
                        onChanged: (val) {
                          setState(() {
                            s['isActive'] = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(s['desc'],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Win Rate', '${s['winRate']}%',
                          AppColors.bullishGreen),
                      _buildMetric('Profit Factor', '${s['profitFactor']}',
                          AppColors.goldAccent),
                      _buildMetric(
                          'Sample Trades', '${s['trades']}', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(String title, String val, Color color) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

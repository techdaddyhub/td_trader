// MODULE 1: AI MULTI-MARKET SCANNER SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/widgets/common_widgets.dart';

class MarketScannerScreen extends StatefulWidget {
  const MarketScannerScreen({super.key});

  @override
  State<MarketScannerScreen> createState() => _MarketScannerScreenState();
}

class _MarketScannerScreenState extends State<MarketScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScannerProvider>(context, listen: false).fetchOpportunities();
    });
  }

  void _showScoreBreakdownDialog(BuildContext context, SignalModel signal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            ScoreBadge(score: signal.score, size: 36),
            const SizedBox(width: 12),
            Text('${signal.instrument} Opportunity Score Breakdown',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow('Trend Alignment',
                '${signal.scoreBreakdown.trendAlignment} / 20.0'),
            _buildMetricRow('Technical Confirmation',
                '${signal.scoreBreakdown.technicalConfirmation} / 20.0'),
            _buildMetricRow(
                'Momentum', '${signal.scoreBreakdown.momentum} / 15.0'),
            _buildMetricRow('Market Structure',
                '${signal.scoreBreakdown.marketStructure} / 15.0'),
            _buildMetricRow(
                'Volatility', '${signal.scoreBreakdown.volatility} / 10.0'),
            _buildMetricRow(
                'Risk / Reward', '${signal.scoreBreakdown.riskReward} / 10.0'),
            _buildMetricRow('Strategy Validation',
                '${signal.scoreBreakdown.strategyValidation} / 10.0'),
            const Divider(color: AppColors.border),
            _buildMetricRow('Total Confluence Score',
                '${signal.scoreBreakdown.totalScore} / 100.0',
                isBold: true),
            const SizedBox(height: 8),
            Text('AI Rationale: ${signal.aiRationale}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE',
                style: TextStyle(color: AppColors.primaryCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isBold ? Colors.white : AppColors.textSecondary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: isBold ? AppColors.primaryCyan : Colors.white,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanner = Provider.of<ScannerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI MULTI-MARKET SCANNER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
            onPressed: () => scanner.fetchOpportunities(),
            tooltip: 'Rescan Markets',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips by Market Category
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: AppConfig.marketCategories.map((cat) {
                final isSelected = scanner.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryCyan,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryCyan
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => scanner.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Timeframe Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: AppConfig.timeframes.map((tf) {
                    final isSelected = scanner.selectedTimeframe == tf;
                    return GestureDetector(
                      onTap: () => scanner.setTimeframe(tf),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryCyan
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  '${scanner.opportunities.length} Setups Found',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Opportunities Live Feed
          Expanded(
            child: scanner.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primaryCyan))
                : scanner.opportunities.isEmpty
                    ? const Center(
                        child: Text(
                            'No qualified opportunities matching current filters.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: scanner.opportunities.length,
                        itemBuilder: (ctx, index) {
                          final opp = scanner.opportunities[index];
                          final isBuy = opp.direction == 'BUY';

                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isBuy
                                    ? AppColors.bullishGreen
                                        .withValues(alpha: 0.3)
                                    : AppColors.bearishRed
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          ScoreBadge(score: opp.score),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    opp.instrument,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isBuy
                                                          ? AppColors
                                                              .bullishGreen
                                                          : AppColors
                                                              .bearishRed,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      opp.direction,
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${opp.timeframe} • ${opp.strategyName}',
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Structure: ${opp.marketStructure}',
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.primaryCyan,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline,
                                            color: AppColors.textSecondary),
                                        onPressed: () =>
                                            _showScoreBreakdownDialog(
                                                context, opp),
                                        tooltip: 'Score breakdown',
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                      color: AppColors.border, height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildPricePill(
                                          'ENTRY', opp.entryPrice.toString()),
                                      _buildPricePill(
                                          'STOP LOSS', opp.stopLoss.toString(),
                                          color: AppColors.bearishRed),
                                      _buildPricePill('TAKE PROFIT',
                                          opp.takeProfit1.toString(),
                                          color: AppColors.bullishGreen),
                                      _buildPricePill(
                                          'R:R', '1:${opp.riskRewardRatio}'),
                                    ],
                                  ),
                                  if (!opp.isRealTime)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.access_time,
                                              size: 12,
                                              color: AppColors.warningAmber),
                                          SizedBox(width: 4),
                                          Text('Delayed Feed Data',
                                              style: TextStyle(
                                                  color: AppColors.warningAmber,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePill(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}

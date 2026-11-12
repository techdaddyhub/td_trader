// MODULE 1: AI MULTI-MARKET SCANNER SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../settings/settings_screen.dart';

class MarketScannerScreen extends StatefulWidget {
  const MarketScannerScreen({super.key});

  @override
  State<MarketScannerScreen> createState() => _MarketScannerScreenState();
}

class _MarketScannerScreenState extends State<MarketScannerScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ScannerProvider>(context, listen: false)
            .fetchOpportunities();
      }
    });
  }

  Future<void> _syncAndRescan() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final scanner = Provider.of<ScannerProvider>(context, listen: false);
    try {
      try {
        await apiService.syncDerivTicks();
      } catch (_) {}
      await apiService.triggerScanNow();
      await scanner.fetchOpportunities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Live market sync complete (${scanner.opportunities.length} setups loaded).'),
            backgroundColor: AppColors.bullishGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Sync error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.bearishRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _confirmAndTradeSetup(SignalModel opp) async {
    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);
    final account = accountProvider.activeAccount;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No active account selected. Go to Trading or Account Manager to connect an account first.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    final lotsController = TextEditingController(text: '0.10');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              opp.direction == 'BUY'
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: opp.direction == 'BUY'
                  ? AppColors.bullishGreen
                  : AppColors.bearishRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Execute ${opp.direction} ${opp.instrument}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account: ${account.brokerName} (${account.accountNumber}) [${account.platform}]',
              style: const TextStyle(
                  color: AppColors.binanceGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMetricRow('Entry Price', opp.entryPrice.toString()),
            _buildMetricRow('Stop Loss', opp.stopLoss.toString()),
            _buildMetricRow('Take Profit', opp.takeProfit1.toString()),
            _buildMetricRow('AI Score', '${opp.score.toInt()}/100'),
            const SizedBox(height: 12),
            TextField(
              controller: lotsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Lot Size / Volume',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: opp.direction == 'BUY'
                  ? AppColors.bullishGreen
                  : AppColors.bearishRed,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('CONFIRM ${opp.direction}'),
          ),
        ],
      ),
    );

    final parsedLots = double.tryParse(lotsController.text.trim()) ?? 0.10;
    lotsController.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await apiService.executeTrade({
        'account_id': account.id,
        'instrument': opp.instrument,
        'direction': opp.direction,
        'lots': parsedLots > 0 ? parsedLots : 0.10,
        'stop_loss': opp.stopLoss,
        'take_profit': opp.takeProfit1,
        'order_type': opp.direction,
      });
      await accountProvider.loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${opp.direction} ${opp.instrument} sent to ${account.platform} (${account.accountNumber})!'),
            backgroundColor: AppColors.bullishGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Execution blocked: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.bearishRed,
          ),
        );
      }
    }
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
          TextButton.icon(
            onPressed: _isSyncing ? null : _syncAndRescan,
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.binanceGold),
                  )
                : const Icon(Icons.sync,
                    size: 16, color: AppColors.binanceGold),
            label: Text(
              _isSyncing ? 'SYNCING' : 'LIVE SYNC',
              style: const TextStyle(
                  color: AppColors.binanceGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ),
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

          if (scanner.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bearishRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.bearishRed.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off,
                      color: AppColors.bearishRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PC Server Unreachable: ${scanner.errorMessage}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: const Text('CONNECT PC',
                        style: TextStyle(
                            color: AppColors.binanceGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
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
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _confirmAndTradeSetup(opp),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBuy
                                            ? AppColors.bullishGreen
                                                .withValues(alpha: 0.18)
                                            : AppColors.bearishRed
                                                .withValues(alpha: 0.18),
                                        foregroundColor: isBuy
                                            ? AppColors.bullishGreen
                                            : AppColors.bearishRed,
                                        side: BorderSide(
                                          color: isBuy
                                              ? AppColors.bullishGreen
                                              : AppColors.bearishRed,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      icon: const Icon(Icons.bolt, size: 16),
                                      label: Text(
                                        'TRADE SETUP (${opp.direction} ${opp.instrument})',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
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

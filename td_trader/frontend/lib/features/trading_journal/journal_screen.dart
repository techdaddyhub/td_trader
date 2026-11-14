// TD TRADER - AI Trading Journal Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class TradingJournalScreen extends StatefulWidget {
  const TradingJournalScreen({super.key});

  @override
  State<TradingJournalScreen> createState() => _TradingJournalScreenState();
}

class _TradingJournalScreenState extends State<TradingJournalScreen> {
  List<dynamic> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJournalEntries();
  }

  Future<void> _fetchJournalEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final entries = await apiService.getJournalEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    } catch (e) {
      debugPrint('Error loading journal: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiService.formatUserFriendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI TRADING JOURNAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
            onPressed: _fetchJournalEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            color: AppColors.bearishRed, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load journal: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchJournalEntries,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : _entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No trading journal entries yet.\nCompleted trades automatically record AI explanations and post-mortem lessons here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (ctx, idx) {
                    final e = _entries[idx];
                    final pnl = (e['pnl'] as num).toDouble();
                    final isWin = pnl >= 0;

                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isWin
                              ? AppColors.bullishGreen.withValues(alpha: 0.3)
                              : AppColors.bearishRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isWin
                                            ? AppColors.bullishGreen
                                            : AppColors.bearishRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e['direction'] ?? 'BUY',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${e['instrument']} (${e['lots']} lots)',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${pnl.toStringAsFixed(2)} (${e['pnl_pct'] ?? 0}%)',
                                  style: TextStyle(
                                    color: isWin
                                        ? AppColors.bullishGreen
                                        : AppColors.bearishRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Entry: ${e['entry_price']} • Exit: ${e['exit_price']}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                                Text(
                                    'Duration: ${e['holding_time_minutes']} min',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.psychology,
                                          size: 16,
                                          color: AppColors.primaryCyan),
                                      SizedBox(width: 6),
                                      Text('AI Post-Trade Explanation:',
                                          style: TextStyle(
                                              color: AppColors.primaryCyan,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e['ai_explanation'] ??
                                        'Adhered to systematic risk rules.',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.3),
                                  ),
                                  if (e['lessons_learned'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text('Key Lesson: ${e['lessons_learned']}',
                                        style: const TextStyle(
                                            color: AppColors.goldAccent,
                                            fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// TD TRADER - Commercial Subscription & Licensing Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMBERSHIP & LICENSING'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTierCard(
            title: 'PAPER & SIMULATION TIER',
            price: 'Free',
            badge: 'ACTIVE TIER',
            badgeColor: AppColors.primaryCyan,
            features: [
              'Simulated Paper Trading Sandbox',
              'AI Multi-Market Scanner (Delayed feeds)',
              'Standard Strategy Backtester',
              'Single Account Monitoring',
            ],
            isCurrent: true,
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            title: 'QUANT PRO TRADER',
            price: '\$99 / month',
            badge: 'RECOMMENDED',
            badgeColor: AppColors.goldAccent,
            features: [
              'Real-Time Tick Multi-Market Feeds (Forex, Crypto, Metals, Indices, Oil)',
              'TD AI Voice Analyst with 4 Personalities & Earcon Audio',
              'Smart Risk Guardian with 16 Independent Pre-Trade Gates',
              'Unlimited MetaTrader 4 & MetaTrader 5 Account Connections',
              'Walk-Forward Optimization & Out-of-Sample Lab',
              'Automated AI Execution with Broker Confirmation Handshake',
            ],
            isCurrent: false,
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            title: 'INSTITUTIONAL HEDGE FUND',
            price: '\$299 / month',
            badge: 'ENTERPRISE',
            badgeColor: AppColors.bullishGreen,
            features: [
              'Multi-Account Portfolio Orchestration & Risk Aggregation',
              'Dedicated VPS Low-Latency Bridge Integration',
              'Custom Quantitative Strategy Builder API',
              'Zero-Commingling Strict Account Isolation Audits',
              'Priority 24/7 Cybersecurity & Bridge Monitoring',
            ],
            isCurrent: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String price,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required bool isCurrent,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isCurrent ? AppColors.primaryCyan : AppColors.border,
            width: isCurrent ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white)),
            const Divider(color: AppColors.border, height: 24),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.primaryCyan),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13))),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? AppColors.surfaceLight
                      : AppColors.primaryCyan,
                  foregroundColor: isCurrent ? Colors.white : Colors.black,
                ),
                onPressed: () {},
                child:
                    Text(isCurrent ? 'CURRENT ACTIVE PLAN' : 'UPGRADE TO PLAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

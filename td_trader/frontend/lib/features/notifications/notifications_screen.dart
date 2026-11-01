// TD TRADER - Advanced Notification Center Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'SIGNAL',
        'title': 'High Confluence Setup Identified',
        'desc': 'BUY opportunity on XAUUSD (H1). Score: 89.8/100. Structure: BULLISH_BOS.',
        'time': '2m ago',
        'icon': Icons.radar,
        'color': AppColors.bullishGreen
      },
      {
        'type': 'EXECUTION',
        'title': 'Order Filled & Confirmed',
        'desc': 'Broker confirmed ticket #MT_MT5_108422. Fill: 1.08520, Slippage: 0.2 pips.',
        'time': '14m ago',
        'icon': Icons.check_circle,
        'color': AppColors.primaryCyan
      },
      {
        'type': 'RISK',
        'title': 'Risk Guardian Protection Engaged',
        'desc': 'Daily loss threshold monitoring nominal. Free margin: \$9,850.00.',
        'time': '1h ago',
        'icon': Icons.shield,
        'color': AppColors.warningAmber
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATION CENTER'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (ctx, idx) {
          final n = notifications[idx];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (n['color'] as Color).withOpacity(0.15),
                ),
                child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
              ),
              title: Text(n['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(n['desc'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: Text(n['time'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }
}


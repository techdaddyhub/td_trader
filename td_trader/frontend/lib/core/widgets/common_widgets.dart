// TD TRADER - Reusable Quantitative Fintech Widgets
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ScoreBadge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreBadge({super.key, required this.score, this.size = 46.0});

  Color _getScoreColor() {
    if (score >= 85) return AppColors.bullishGreen;
    if (score >= 70) return AppColors.primaryCyan;
    if (score >= 50) return AppColors.warningAmber;
    return AppColors.bearishRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        score.toStringAsFixed(0),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class VoiceWaveWidget extends StatelessWidget {
  final bool isSpeaking;
  final bool isListening;
  final VoidCallback onMicTap;
  final VoidCallback onInterruptTap;

  const VoiceWaveWidget({
    super.key,
    required this.isSpeaking,
    required this.isListening,
    required this.onMicTap,
    required this.onInterruptTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? AppColors.primaryCyan : AppColors.border,
          width: isSpeaking ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? AppColors.bearishRed : AppColors.primaryCyan,
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpeaking ? 'TD AI Voice Speaking...' : (isListening ? 'Listening for command...' : 'TD AI Voice Ready'),
                  style: TextStyle(
                    color: isSpeaking ? AppColors.primaryCyan : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap mic to ask "Analyse gold" or "Check my account risk"',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: AppColors.bearishRed, size: 28),
              onPressed: onInterruptTap,
              tooltip: 'Interrupt speech',
            ),
        ],
      ),
    );
  }
}

class EmergencyControlPanel extends StatelessWidget {
  final int accountId;
  final Function(String action, bool confirm) onAction;

  const EmergencyControlPanel({
    super.key,
    required this.accountId,
    required this.onAction,
  });

  void _showCloseAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('EMERGENCY: CLOSE ALL POSITIONS', style: TextStyle(color: AppColors.bearishRed)),
        content: const Text(
          'Are you sure you want to market-close ALL open positions immediately?\n\nThis will liquidate all open trades on this account.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bearishRed),
            onPressed: () {
              Navigator.pop(ctx);
              onAction('CLOSE_ALL_POSITIONS', true);
            },
            child: const Text('CONFIRM CLOSE ALL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bearishRed.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.bearishRed),
              SizedBox(width: 8),
              Text(
                'SMART RISK GUARDIAN - EMERGENCY PANEL',
                style: TextStyle(color: AppColors.bearishRed, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.pause_circle_filled, size: 16),
                label: const Text('PAUSE AI TRADING'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
                onPressed: () => onAction('PAUSE_AI', false),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle, size: 16),
                label: const Text('STOP NEW TRADES'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight, foregroundColor: Colors.white),
                onPressed: () => onAction('STOP_NEW_TRADES', false),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_presentation, size: 16),
                label: const Text('CANCEL PENDING'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight, foregroundColor: Colors.white),
                onPressed: () => onAction('CANCEL_PENDING', false),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.dangerous, size: 16),
                label: const Text('CLOSE ALL POSITIONS'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.bearishRed, foregroundColor: Colors.white),
                onPressed: () => _showCloseAllConfirmation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


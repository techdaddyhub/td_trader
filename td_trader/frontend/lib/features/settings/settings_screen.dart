// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Application Settings & Risk Presets Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/techdaddy_logo.dart';
import '../../core/providers/app_state_providers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & SYSTEM PRESETS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Voice Assistant Settings
          _buildSectionHeader('TD AI VOICE CONFIGURATION'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: voice.selectedPersonality,
                    decoration: const InputDecoration(labelText: 'Voice Personality'),
                    items: const [
                      DropdownMenuItem(value: 'Aria_Fintech_Pro', child: Text('Aria (Female Fintech Lead)')),
                      DropdownMenuItem(value: 'Sophia_Macro_Strategist', child: Text('Sophia (Global Macro)')),
                      DropdownMenuItem(value: 'Marcus_Quant_Lead', child: Text('Marcus (Male Quant Lead)')),
                      DropdownMenuItem(value: 'Alexander_Institutional', child: Text('Alexander (Risk Arbiter)')),
                    ],
                    onChanged: (val) => voice.setPersonality(val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Speech Speed:', style: TextStyle(color: AppColors.textSecondary)),
                      Text('${voice.speechSpeed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                    ],
                  ),
                  Slider(
                    value: voice.speechSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) => voice.setSpeed(val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Volume:', style: TextStyle(color: AppColors.textSecondary)),
                      Text('${(voice.volume * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                    ],
                  ),
                  Slider(
                    value: voice.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) => voice.setVolume(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security & Encryption Status
          _buildSectionHeader('CYBERSECURITY & ENCRYPTION'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSecurityRow('Broker Credential Storage', 'AES-256 Fernet Encrypted', AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow('User Password Hashing', 'PBKDF2-HMAC-SHA256 (600k rounds)', AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow('API Token Standard', 'RFC 7519 HMAC-SHA256 JWT', AppColors.bullishGreen),
                  const Divider(color: AppColors.border),
                  _buildSecurityRow('Account Isolation', 'Strict Zero-Commingling Enforced', AppColors.primaryCyan),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About & TechDaddy Ownership
          _buildSectionHeader('OWNERSHIP & LEGAL NOTICES'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  TechDaddyLogo(size: 64, showText: true, showCopyright: true),
                  SizedBox(height: 12),
                  Text(
                    'Exclusive Property of TechDaddy Fintech Systems',
                    style: TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All algorithms, neural network architectures, Smart Risk Guardian rules, and MetaTrader bridge protocols are protected under international copyright law.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSecurityRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


// MODULE 2: TD AI VOICE - PERSONAL TRADING ANALYST SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/widgets/common_widgets.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final TextEditingController _textController = TextEditingController();

  final List<String> _quickQuestions = [
    'Analyse gold for me',
    'Explain the latest signal',
    'Why did the AI enter this trade?',
    'What is happening in the market?',
    'What is my account risk?',
    'Explain my losses today',
    'Which market has the strongest validated setup?'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitQuestion(String q) {
    if (q.trim().isEmpty) return;
    Provider.of<VoiceProvider>(context, listen: false).askQuestion(q.trim());
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TD AI VOICE ANALYST'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_voice, color: AppColors.primaryCyan),
            onSelected: (val) => voice.setPersonality(val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'Aria_Fintech_Pro', child: Text('Aria (Female Fintech Pro)')),
              const PopupMenuItem(value: 'Sophia_Macro_Strategist', child: Text('Sophia (Global Macro)')),
              const PopupMenuItem(value: 'Marcus_Quant_Lead', child: Text('Marcus (Male Quant Lead)')),
              const PopupMenuItem(value: 'Alexander_Institutional', child: Text('Alexander (Risk Arbiter)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice Personality & Speed Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voice: ${voice.selectedPersonality.replaceAll("_", " ")}',
                  style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${voice.speechSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Speaking Status Banner & Interrupt Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: VoiceWaveWidget(
              isSpeaking: voice.isSpeaking,
              isListening: voice.isListening,
              onMicTap: () => voice.toggleListening(),
              onInterruptTap: () => voice.interruptSpeech(),
            ),
          ),

          // Quick Analyst Prompt Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _quickQuestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: AppColors.surfaceLight,
                    onPressed: () => _submitQuestion(q),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Conversation Transcript Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: voice.messages.length,
              itemBuilder: (ctx, index) {
                final msg = voice.messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryCyan.withOpacity(0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isUser ? AppColors.primaryCyan : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy,
                              size: 14,
                              color: isUser ? AppColors.primaryCyan : AppColors.goldAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'YOU' : 'TD AI ANALYST',
                              style: TextStyle(
                                color: isUser ? AppColors.primaryCyan : AppColors.goldAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg['text'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // User Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask your AI personal trading analyst...',
                      prefixIcon: Icon(Icons.record_voice_over, color: AppColors.primaryCyan),
                    ),
                    onSubmitted: (val) => _submitQuestion(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primaryCyan),
                  onPressed: () => _submitQuestion(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


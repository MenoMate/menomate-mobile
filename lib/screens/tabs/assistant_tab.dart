import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/care.dart';
import '../../services/api_service.dart';
import '../../services/ble_service.dart';
import '../home_screen.dart';

class CarePromptData {
  final String text;
  final String intent;
  const CarePromptData(this.text, this.intent);
}

class CareInitialPromptNotifier extends Notifier<CarePromptData?> {
  @override
  CarePromptData? build() => null;

  void setPrompt(CarePromptData? prompt) => state = prompt;
  void clear() => state = null;
}

final careInitialPromptProvider =
    NotifierProvider<CareInitialPromptNotifier, CarePromptData?>(CareInitialPromptNotifier.new);

class AssistantTab extends ConsumerStatefulWidget {
  const AssistantTab({super.key});

  @override
  ConsumerState<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends ConsumerState<AssistantTab> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = ref.read(careInitialPromptProvider);
      if (initial != null) {
        ref.read(careInitialPromptProvider.notifier).clear();
        _sendMessage(initial.text, intent: initial.intent);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String messageText, {String? intent}) async {
    final text = messageText.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, {
        'isUser': true,
        'text': text,
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final request = CareInteractionRequest(
        intent: intent ?? 'wellness_help',
        userMessage: text,
      );

      final response = await api.postCareInteraction(request);

      if (response != null && mounted) {
        setState(() {
          _messages.insert(0, {
            'isUser': false,
            'text': response.responseText,
            'intent': response.intent,
            'actions': response.suggestedActions,
            'therapyProfile': response.therapyProfile,
            'isAi': response.isAiGenerated,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'isUser': false,
            'text': 'MenoMate Care is currently experiencing a connection issue. Please check your network and try again.',
            'isAi': false,
          });
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleActionTap(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('log') || lower.contains('symptom')) {
      context.push('/logger');
    } else if (lower.contains('calendar') || lower.contains('history') || lower.contains('cycle')) {
      // In home screen, calendar is tab index 2
      ref.read(homeTabIndexProvider.notifier).setIndex(2);
    } else if (lower.contains('connect') || lower.contains('wearable') || lower.contains('pair')) {
      // Navigate to Home tab (index 0) where the wearable telemetry card is located
      ref.read(homeTabIndexProvider.notifier).setIndex(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use the MenoMate Wearable card on Home to scan and pair your device.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (lower.contains('therapy') || lower.contains('thermal')) {
      final bleService = ref.read(bleServiceProvider);
      if (!bleService.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wearable not connected. Please pair your device first.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        bleService.sendTherapyCommand(
          targetTemperature: 38.0,
          vibrationMode: 'gentle',
          vibrationIntensity: 1,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started $action.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CarePromptData?>(careInitialPromptProvider, (previous, next) {
      if (next != null) {
        ref.read(careInitialPromptProvider.notifier).clear();
        _sendMessage(next.text, intent: next.intent);
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.spa_rounded, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'MenoMate Care',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Conversation or Empty State
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg, context);
                      },
                    ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MenoMate Care is thinking...',
                        style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),

            // Quick Actions Horizontal Bar
            _buildQuickActionsBar(context),

            // Chat Input Box
            _buildChatInputBox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'How can I help today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I can help you understand your cycle, symptoms, pain patterns, and how you\'ve used MenoMate.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickChip("What's happening today?", 'cycle_insight'),
                _buildQuickChip('Help with my current pain', 'pain_help'),
                _buildQuickChip('What patterns do you notice?', 'pattern_summary'),
                _buildQuickChip('What helped me before?', 'therapy_recommendation'),
                _buildQuickChip('Prepare for my next period', 'cycle_insight'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String intent) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outline),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: _isLoading ? null : () => _sendMessage(label, intent: intent),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isUser = msg['isUser'] == true;
    final String text = msg['text'] ?? '';
    final List<dynamic>? actions = msg['actions'] as List<dynamic>?;
    final String? therapyProfile = msg['therapyProfile'] as String?;

    final bool isRedFlag = text.contains('URGENT CLINICAL SAFETY ADVISORY');

    if (isRedFlag) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                SizedBox(width: 8),
                Text(
                  'CLINICAL SAFETY ADVISORY',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.red, fontSize: 13, height: 1.4),
            ),
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: actions
                    .map((act) => ActionChip(
                          label: Text(act.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.redAccent,
                          onPressed: () => _handleActionTap(act.toString()),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(2),
          ),
          border: isUser ? null : Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : colorScheme.onSurface,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Therapy Recommendation Banner
            if (therapyProfile != null && therapyProfile.isNotEmpty) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final bleConnected = ref.watch(bleConnectedProvider);
                  final profileUpper = therapyProfile.toUpperCase();
                  final profileCapitalized = profileUpper.length > 1
                      ? profileUpper[0] + profileUpper.substring(1).toLowerCase()
                      : profileUpper;

                  if (!bleConnected) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "I'd suggest the $profileUpper profile for you right now. Your wearable isn't connected, so you can use this recommendation once your device is paired.",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Wearable not connected',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _handleActionTap('connect wearable'),
                                icon: const Icon(Icons.bluetooth_searching, size: 16),
                                label: const Text('Connect Wearable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // Connected state
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "I'd suggest the $profileUpper profile for you right now.",
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _handleActionTap('Start $profileCapitalized Thermal Therapy'),
                          icon: const Icon(Icons.waves, size: 16),
                          label: Text('Start $profileCapitalized Thermal Therapy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // Action Chips
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: actions
                    .map((action) => ActionChip(
                          label: Text(action.toString(), style: const TextStyle(fontSize: 11)),
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                          labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                          onPressed: () => _handleActionTap(action.toString()),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSmallQuickAction('Cycle insight', 'cycle_insight', colorScheme),
          _buildSmallQuickAction('Pain help', 'pain_help', colorScheme),
          _buildSmallQuickAction('What helped before?', 'therapy_recommendation', colorScheme),
          _buildSmallQuickAction('Patterns', 'pattern_summary', colorScheme),
          _buildSmallQuickAction('Next period', 'cycle_insight', colorScheme),
        ],
      ),
    );
  }

  Widget _buildSmallQuickAction(String label, String intent, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
        backgroundColor: colorScheme.surface,
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: _isLoading ? null : () => _sendMessage(label, intent: intent),
      ),
    );
  }

  Widget _buildChatInputBox(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask about your cycle, symptoms, or therapy...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
              ),
              onSubmitted: (val) {
                if (!_isLoading) _sendMessage(val);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            onPressed: _isLoading
                ? null
                : () {
                    _sendMessage(_textController.text);
                  },
          ),
        ],
      ),
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/care.dart';
import '../../providers/care_session_provider.dart';
import '../../providers/offline_mode_provider.dart';
import '../../widgets/care_message_bubble.dart';
import '../../widgets/menomate_logo.dart';
import '../../services/api_service.dart';
import '../../services/ble_service.dart';
import '../home_screen.dart';

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
    final topic = intent ?? 'wellness_help';
    // Active-session memory: the in-flight message travels as
    // user_message; retained prior turns travel as recent_turns.
    final priorTurns = List<CareTurn>.unmodifiable(
      ref.read(careSessionProvider),
    );
    ref.read(careSessionProvider.notifier).addUserTurn(text, topic: topic);

    // MenoMate Care needs an account as well as connectivity: local-only
    // users get a clear sign-in explanation instead of a raw auth error.
    if (ref.read(isOfflineTrackingProvider)) {
      setState(() {
        _messages.insert(0, {'isUser': true, 'text': text});
      });
      _scrollToBottom();
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'isUser': false,
            'text':
                'You\u2019re using MenoMate offline. Sign in to use MenoMate '
                'Care, which needs an internet connection and an account. '
                'Your history, logs, and calendar remain available offline.',
            'isAi': false,
          });
        });
        _scrollToBottom();
      }
      return;
    }

    // Care is online-only: never spin forever or fabricate a reply offline.
    // A plugin failure counts as offline too (fail closed, never claim AI).
    bool online = false;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      online = connectivity.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      online = false;
    }
    setState(() {
      _messages.insert(0, {'isUser': true, 'text': text});
      _isLoading = online;
    });
    _scrollToBottom();
    if (!online) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'isUser': false,
            'text':
                'MenoMate Care needs an internet connection. '
                'Your history, logs, and calendar remain available offline.',
            'isAi': false,
          });
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final request = buildCareRequest(
        text: text,
        intent: topic,
        priorTurns: priorTurns,
      );

      final response = await api.postCareInteraction(request);

      if (mounted) {
        ref
            .read(careSessionProvider.notifier)
            .addCareTurn(
              response.responseText,
              topic: response.intent,
              facts: {
                if (response.therapyProfile != null)
                  'therapy_profile': response.therapyProfile!,
              },
            );
        setState(() {
          _messages.insert(0, {
            'isUser': false,
            'text': response.responseText,
            'intent': response.intent,
            'tier': response.tier,
            'actions': response.actions,
            'therapyProfile': response.therapyProfile,
            'isAi': response.isAiGenerated,
            'disclaimer': response.disclaimer,
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

  void _startNewChat() {
    ref.read(careSessionProvider.notifier).clear();
    setState(() {
      _messages.clear();
      _isLoading = false;
    });
  }

  /// Semantic action routing: the backend-chosen id decides, never the
  /// display label. Pure [resolveCareActionTarget] mapping underneath.
  void _handleActionTap(CareAction action) {
    switch (resolveCareActionTarget(action.id)) {
      case CareActionTarget.logger:
        context.push('/logger');
      case CareActionTarget.historyTab:
        // History is a pushed detail route, not a tab: back returns here.
        context.push('/history');
      case CareActionTarget.homeTab:
        // Navigate to Home tab (index 0) where the wearable telemetry card is located
        ref.read(homeTabIndexProvider.notifier).setIndex(0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Use the MenoMate Wearable card on Home to scan and pair your device.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      case CareActionTarget.emergencyInfo:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please contact emergency services or your doctor directly.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      case CareActionTarget.therapy:
        // Step 7 — truthful therapy behavior. BLE control is not
        // implemented (BleService.sendTherapyCommand is a stub), so a tap
        // must never claim therapy started and must never fire parameters.
        // The approved setup stays pending until a real BLE write lands.
        final bleService = ref.read(bleServiceProvider);
        if (!bleService.isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Wearable not connected. Pair your device to use the recommended setup.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint(
            'Therapy start requested (${action.label}) — BLE control not yet implemented.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Therapy control isn't available yet — the approved setup will apply once BLE control lands.",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      case CareActionTarget.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Transparent: the shared ThemeAtmosphereBackground painted by
      // HomeScreen shows through.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Root tab: never show a back arrow here.
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const MenoMateBrandLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              'MenoMate Care',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Start new chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _isLoading ? null : _startNewChat,
          ),
        ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MenoMate Care is thinking...',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 32,
              ),
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
              'I can help you understand your cycle, symptoms, pain patterns, and how you\'ve used MenoMate. Care needs an internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // One canonical quick-prompt set (single prompt system:
            // the bottom bar and Home row were removed as duplicates).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickChip("What's happening today?", 'cycle_insight'),
                _buildQuickChip('Help with my current pain', 'pain_help'),
                _buildQuickChip(
                  'What patterns do you notice?',
                  'pattern_summary',
                ),
                _buildQuickChip(
                  'What helped me before?',
                  'therapy_recommendation',
                ),
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
    final bleConnected = ref.watch(bleConnectedProvider);
    return CareMessageBubble(
      message: msg,
      bleConnected: bleConnected,
      onAction: _handleActionTap,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
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

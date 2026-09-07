import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/care.dart';
import '../../services/api_service.dart';

class AssistantTab extends ConsumerStatefulWidget {
  const AssistantTab({super.key});

  @override
  ConsumerState<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends ConsumerState<AssistantTab> {
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  void _sendIntent(String intent, String displayLabel) async {
    setState(() {
      _messages.insert(0, {'isUser': true, 'text': displayLabel});
      _isLoading = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.postCareInteraction(CareInteractionRequest(intent: intent));
      
      if (response != null && mounted) {
        setState(() {
          _messages.insert(0, {'isUser': false, 'text': response.responseText, 'actions': response.suggestedActions});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {'isUser': false, 'text': 'Sorry, I am having trouble connecting right now.'});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Care Assistant', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['isUser'], msg['text'], msg['actions']);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildQuickActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text, List<dynamic>? actions) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? Colors.pinkAccent : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: actions
                    .map((action) => ActionChip(
                          label: Text(action, style: const TextStyle(fontSize: 12)),
                          onPressed: () {},
                          backgroundColor: Colors.blue.shade50,
                        ))
                    .toList(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionButton('Cycle Insight', 'cycle_insight'),
          _buildActionButton('Symptom Help', 'symptom_insight'),
          _buildActionButton('Pain Relief', 'pain_help'),
          _buildActionButton('Wellness Tips', 'wellness_help'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String intent) {
    return ActionChip(
      label: Text(label),
      onPressed: _isLoading ? null : () => _sendIntent(intent, label),
      backgroundColor: Colors.pink.shade50,
      labelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
    );
  }
}

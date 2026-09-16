import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/care.dart';

/// One Care chat message bubble, rendered by deterministic tier.
///
/// - urgent → fixed safety card (keyed on `tier`, never on message text).
/// - advisory → caution frame reusing the same card language.
/// - info → normal user/assistant bubbles.
/// Actions route on semantic [CareAction.id] via the [onAction] callback;
/// labels are display-only and never matched.
class CareMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool bleConnected;
  final void Function(CareAction action) onAction;

  const CareMessageBubble({
    super.key,
    required this.message,
    required this.bleConnected,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['isUser'] == true;
    final String text = message['text'] as String? ?? '';
    final List<CareAction> actions =
        (message['actions'] as List<CareAction>?) ?? const [];
    final String? therapyProfile = message['therapyProfile'] as String?;
    final String tier = message['tier'] as String? ?? 'info';

    if (!isUser && tier == 'urgent') {
      return _buildTierCard(
        context,
        text: text,
        actions: actions,
        color: Colors.red,
        backgroundAlpha: 0.1,
        borderAlpha: 0.4,
        title: 'CLINICAL SAFETY ADVISORY',
        icon: Icons.warning_amber_rounded,
        chipBackground: Colors.redAccent,
        chipForeground: Colors.white,
      );
    }

    if (!isUser && tier == 'advisory') {
      return _buildTierCard(
        context,
        text: text,
        actions: actions,
        color: Colors.orange.shade800,
        backgroundAlpha: 0.08,
        borderAlpha: 0.45,
        title: 'HEALTH NOTE',
        icon: Icons.info_outline,
        chipBackground: Colors.orange.shade700,
        chipForeground: Colors.white,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                // Warm pale neutral instead of pure white on the rose
                // user bubble, matching the dark text philosophy.
                color: isUser
                    ? MenoMateTheme.starryText
                    : colorScheme.onSurface,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Therapy Recommendation Banner
            if (therapyProfile != null && therapyProfile.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTherapyBanner(context, therapyProfile),
            ],

            // Action Chips
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: actions
                    .map((action) => ActionChip(
                          label: Text(action.label, style: const TextStyle(fontSize: 11)),
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                          labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                          onPressed: () => onAction(action),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String text,
    required List<CareAction> actions,
    required Color color,
    required double backgroundAlpha,
    required double borderAlpha,
    required String title,
    required IconData icon,
    required Color chipBackground,
    required Color chipForeground,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: borderAlpha), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: actions
                  .map((action) => ActionChip(
                        label: Text(action.label,
                            style: TextStyle(color: chipForeground, fontSize: 12)),
                        backgroundColor: chipBackground,
                        onPressed: () => onAction(action),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTherapyBanner(BuildContext context, String therapyProfile) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  onPressed: () => onAction(
                    const CareAction(id: 'connect_wearable', label: 'Connect Wearable'),
                  ),
                  icon: const Icon(Icons.bluetooth_searching, size: 16),
                  label: const Text('Connect Wearable',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            onPressed: () => onAction(CareAction(
              id: 'view_therapy',
              label: 'Start $profileCapitalized Thermal Therapy',
            )),
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
  }
}

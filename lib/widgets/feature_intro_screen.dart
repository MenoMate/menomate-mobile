import 'package:flutter/material.dart';

import '../widgets/menomate_logo.dart';

/// Reusable full-screen first-use explainer for optional features.
///
/// Calm by design: brand mark, title, a few short body lines, one primary
/// action and one quiet skip. It never blocks core usage — callers decide
/// when to show it and persist the dismissal (see
/// `OfflineModeNotifier.dismissFeature/isFeatureDismissed`), so a skipped
/// intro is never shown again. Currently used for Health Context; future
/// features add their own copy without touching this widget.
class FeatureIntroScreen extends StatelessWidget {
  /// Short title, e.g. "Help MenoMate understand your context".
  final String title;

  /// 2–4 short paragraphs. Keep each to a line or two; no walls of text.
  final List<String> body;

  /// Small supporting icon rendered in a soft circle above the title.
  final IconData icon;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  final String secondaryLabel;
  final VoidCallback? onSecondary;

  const FeatureIntroScreen({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: MenoMateLogo(size: 56)),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: colorScheme.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final paragraph in body) ...[
                    Text(
                      paragraph,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

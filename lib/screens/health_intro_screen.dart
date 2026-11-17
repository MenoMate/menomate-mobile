import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/feature_intro_screen.dart';

/// First-use feature key for Health Context dismissal persistence.
const kHealthIntroFeature = 'health_context';

/// Calm, skippable first-use explainer for Health Context. Shown once when
/// the user first opens Health & Context — never blocks tracking, never
/// repeats after dismissal.
class HealthIntroScreen extends ConsumerWidget {
  const HealthIntroScreen({super.key});

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      await ref
          .read(offlineModeProvider.notifier)
          .dismissFeature(kHealthIntroFeature, userId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureIntroScreen(
      icon: Icons.favorite_outline,
      title: 'Help MenoMate understand your context',
      body: const [
        'Your health history can sometimes provide useful context for the symptoms and patterns you track.',
        'You can optionally tell MenoMate about conditions, medications, contraception, pregnancy/fertility context, or anything else you\u2019d like it to know.',
        'This information helps personalize your experience. It does not diagnose you.',
      ],
      primaryLabel: 'Explore Health Context',
      onPrimary: () async {
        await _dismiss(context, ref);
        if (context.mounted) context.pushReplacement('/profile/health');
      },
      secondaryLabel: 'Skip for now',
      onSecondary: () async {
        await _dismiss(context, ref);
        if (context.mounted) context.pop();
      },
    );
  }
}

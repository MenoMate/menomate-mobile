import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../content/insight_library.dart';
import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../providers/cycle_provider.dart';

/// Last-good insight holder (plain Riverpod state, no new cache layer).
///
/// Single resolution per notifier lifetime: the value survives Home
/// revisits and pull-to-refresh cycles (no spinner flash, no repeated
/// work); only an explicit [refresh] re-resolves, and cycle invalidation
/// never does. The served content always comes from the deterministic
/// local [insight library], read through [InsightInput] — no network,
/// no AI, fully offline.
///
/// Future-AI seam: an optional enrichment layer would consume an
/// [InsightInput] and return an [InsightPair] (the exact contract
/// [selectInsightPair] satisfies); the widget below only ever sees
/// [InsightPair], so such a layer plugs in without touching UI code.
/// Not implemented here — the local library is the authoritative
/// fallback and must never gain a network/AI dependency.
class DailyInsightNotifier extends Notifier<AsyncValue<InsightPair?>> {
  @override
  AsyncValue<InsightPair?> build() {
    unawaited(_resolveOnce());
    return const AsyncLoading();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _resolveOnce();
  }

  /// Resolves exactly once per call. Never throws and never hangs on a
  /// failed cycle read: provider errors are read as values (never awaited
  /// as futures), so any failure lands on the safe fallback pair instead
  /// of an error card or an eternal spinner.
  Future<void> _resolveOnce() async {
    final input = await _readInsightInput();
    if (!ref.mounted) return;
    state = AsyncData(selectInsightPair(input));
  }

  Future<InsightInput> _readInsightInput() async {
    final settled = await _firstSettledCycle();
    final data = settled.value?.dataOrNull;
    return InsightInput(
      hasData: data?.hasData ?? false,
      phase: data?.phase ?? 'unknown',
      menstrualDay:
          (data?.isBleeding ?? false) ? data?.currentCycleDay : null,
    );
  }

  /// First terminal cycle state. Reads the provider as data and, only
  /// while still loading, waits for the next settled state via a
  /// short-lived listener — never by awaiting the provider future,
  /// which does not complete when the provider is in error.
  Future<AsyncValue<DataState<CurrentCycleResponse?>>>
      _firstSettledCycle() async {
    final current = ref.read(currentCycleProvider);
    if (current.hasValue || current.hasError) return current;
    final completer =
        Completer<AsyncValue<DataState<CurrentCycleResponse?>>>();
    final sub = ref.listen<AsyncValue<DataState<CurrentCycleResponse?>>>(
      currentCycleProvider,
      (previous, next) {
        if ((next.hasValue || next.hasError) && !completer.isCompleted) {
          completer.complete(next);
        }
      },
    );
    try {
      return await completer.future;
    } finally {
      sub.close();
    }
  }
}

final dailyInsightProvider =
    NotifierProvider<DailyInsightNotifier, AsyncValue<InsightPair?>>(
  DailyInsightNotifier.new,
);

class DailyInsightCard extends ConsumerStatefulWidget {
  const DailyInsightCard({super.key});

  @override
  ConsumerState<DailyInsightCard> createState() => _DailyInsightCardState();
}

class _DailyInsightCardState extends ConsumerState<DailyInsightCard> {
  bool _isDismissed = false;
  late final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final insightAsync = ref.watch(dailyInsightProvider);

    return Dismissible(
      key: const Key('daily_insight_card'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() {
          _isDismissed = true;
        });
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
        child: Padding(
          // Tight vertical padding; the card height is driven by the
          // content, with only enough room to breathe.
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: insightAsync.when(
            data: (pair) {
              final slides = pair == null
                  ? const [
                      _InsightSlide(
                        title: 'Daily insight',
                        piece: InsightPiece(
                          body: 'Listen to your body today and take it easy.',
                        ),
                      ),
                    ]
                  : [
                      _InsightSlide(
                          title: 'Today’s insight', piece: pair.insight),
                      _InsightSlide(
                          title: 'Helpful today', piece: pair.action),
                    ];
              return Column(
                key: const Key('daily_insight_content'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manual swipe only: no autoplay, no timers.
                  // Compact by design: the ring stays the primary surface.
                  // Fits a 3-line body plus the tiny attribution at phone
                  // widths; em-dash phrasing can wrap to three lines.
                  // Sized to the tallest slide — no empty rectangle.
                  SizedBox(
                    height: 100,
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => slides[i],
                    ),
                  ),
                  if (slides.length > 1) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < slides.length; i++)
                          Container(
                            width: 5,
                            height: 5,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => Text(
              'Could not fetch your daily insight. Please try again later.',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

/// One compact slide: short title, 1–2 sentence body, and a tiny source
/// label only when the piece opts into visible attribution.
class _InsightSlide extends StatelessWidget {
  final String title;
  final InsightPiece piece;

  const _InsightSlide({required this.title, required this.piece});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          piece.body,
          style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.35),
        ),
        if (piece.showAttribution && piece.attributionLabel != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              piece.attributionLabel!,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.secondary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

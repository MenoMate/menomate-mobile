/// Deterministic, evidence-informed Daily Insight content library.
///
/// This is the guaranteed base layer for Daily Insight: a small set of
/// excellent, reusable insight/action pairs selected purely from the
/// current cycle context (phase + menstrual day). No network, no AI, no
/// inference — selection is a pure function, so content is always
/// evidence-bounded and fully testable.
///
/// An optional AI enrichment layer may later plug in *around* this library
/// (select-then-enhance) without changing the UI or replacing these pairs.
/// It is not implemented here.
///
/// Content rules enforced by tests in test/insight_library_test.dart:
/// - 1 insight + 1 complementary action per context (never duplicates).
/// - Short enough to read in seconds: every body is a single concise
///   line or two (140 characters max), never a paragraph wall.
/// - No ring facts (day numbers, phase names, dates, confidence, stats).
/// - No inappropriate certainty ("will", "always", guarantees), no
///   diagnosis language, no prescriptions/dosages, no hormone-mechanism
///   claims, no medication or supplement recommendations.
/// - Nutrition appears only as an option among other suggestions, framed
///   conservatively: foods may be named as nutrient sources, never as
///   treatments ("X reduces cramps" is banned); no chocolate-as-treatment,
///   no supplement or dosage talk. Food-based magnesium (nuts, seeds,
///   legumes, whole grains, leafy greens) is the only mineral mention.
/// - Every substantive medical claim carries real source metadata; only a
///   few pieces show a tiny visible attribution where it adds credibility.
///   Simple general nutrition needs no visible source.
library;

/// One slide of content: a short body plus optional source metadata.
///
/// [showAttribution] gates the tiny visible label ([attributionLabel]);
/// metadata is always present on substantive claims regardless of display.
class InsightPiece {
  final String body;
  final String? sourceName;
  final String? sourceType;
  final String? sourceId;
  final bool showAttribution;
  final String? attributionLabel;

  const InsightPiece({
    required this.body,
    this.sourceName,
    this.sourceType,
    this.sourceId,
    this.showAttribution = false,
    this.attributionLabel,
  });
}

/// The two complementary slides served together for one context.
class InsightPair {
  final InsightPiece insight;
  final InsightPiece action;

  const InsightPair({required this.insight, required this.action});
}

/// Deterministic insight context: the complete input a resolution needs.
///
/// The notifier builds this from already-available cycle facts; the local
/// selector below consumes it. A future optional AI enrichment provider
/// would consume exactly this object and return an [InsightPair] — the UI
/// only ever sees [InsightPair], so such a layer plugs in without touching
/// widget code. No AI is implemented here: the local library stays the
/// authoritative fallback and works fully offline.
class InsightInput {
  final bool hasData;
  final String phase;
  final int? menstrualDay;

  const InsightInput({
    required this.hasData,
    required this.phase,
    this.menstrualDay,
  });
}

/// Contexts the selector distinguishes. Menstrual day comes from the
/// server-provided cycle day while bleeding; it is read, never computed.
enum InsightContext {
  menstrualEarly,
  menstrualLate,
  menstrualUnknown,
  follicular,
  ovulation,
  luteal,
  noData,
}

/// All served pairs, keyed by context. Seven pairs by design: excellent
/// and reusable beats dozens of generic tips.
const Map<InsightContext, InsightPair> insightPairs = {
  InsightContext.menstrualEarly: InsightPair(
    insight: InsightPiece(
      body:
          'Cramps often peak in the first day or two, then ease.',
      sourceName: 'ACOG',
      sourceType: 'guideline',
      sourceId: 'ACOG-FAQ-dysmenorrhea',
      showAttribution: true,
      attributionLabel: 'ACOG',
    ),
    action: InsightPiece(
      body:
          'Warmth on the lower belly — a bath, bottle, or patch — may ease cramps.',
      sourceName: 'Yuan et al. 2026 systematic review',
      sourceType: 'systematic-review',
      sourceId: 'DOI 10.3389/fmed.2025.1730505',
      showAttribution: true,
      attributionLabel: 'Systematic review',
    ),
  ),
  InsightContext.menstrualLate: InsightPair(
    insight: InsightPiece(
      body:
          'Discomfort often fades as bleeding winds down, though timing varies.',
      sourceName: 'ACOG',
      sourceType: 'guideline',
      sourceId: 'ACOG-FAQ-dysmenorrhea',
    ),
    action: InsightPiece(
      body:
          'A short easy walk or gentle stretching can help you feel more comfortable.',
      sourceName: 'Cochrane review',
      sourceType: 'systematic-review',
      sourceId: 'Cochrane CD004142 (2019)',
    ),
  ),
  InsightContext.menstrualUnknown: InsightPair(
    insight: InsightPiece(
      body: 'Period pain often peaks around the start of bleeding.',
      sourceName: 'ACOG',
      sourceType: 'guideline',
      sourceId: 'ACOG-FAQ-dysmenorrhea',
    ),
    action: InsightPiece(
      body:
          'Keep meals regular today, adding fruit, vegetables, or whole grains when you can.',
    ),
  ),
  InsightContext.follicular: InsightPair(
    insight: InsightPiece(
      body:
          'This is a good window to restart routines that paused for a few days.',
    ),
    action: InsightPiece(
      body:
          'Two or three easy sessions this week — walking, stretching, or yoga — is a steady start.',
      sourceName: 'Cochrane review',
      sourceType: 'systematic-review',
      sourceId: 'Cochrane CD004142 (2019)',
      showAttribution: true,
      attributionLabel: 'Cochrane review',
    ),
  ),
  InsightContext.ovulation: InsightPair(
    insight: InsightPiece(
      body:
          'Cycles vary month to month; a single unusual one is usually not meaningful on its own.',
    ),
    action: InsightPiece(
      body: 'Logging as usual is enough — patterns only show across several cycles.',
    ),
  ),
  InsightContext.luteal: InsightPair(
    insight: InsightPiece(
      body:
          'Good sleep makes discomfort easier to cope with, before and during bleeding.',
      sourceName: 'ACOG',
      sourceType: 'guideline',
      sourceId: 'ACOG-FAQ-dysmenorrhea',
    ),
    action: InsightPiece(
      body:
          'Include a magnesium-rich food today — nuts, seeds, beans, or leafy greens.',
      sourceName: 'USDA FoodData Central',
      sourceType: 'nutrition-database',
      sourceId: 'USDA-FDC',
    ),
  ),
  InsightContext.noData: InsightPair(
    insight: InsightPiece(
      body: 'MenoMate becomes more personal as it learns your cycles.',
    ),
    action: InsightPiece(
      body: 'Log a period or today’s wellness notes to start your history.',
    ),
  ),
};

/// Deterministic context selection from already-available cycle facts.
///
/// - [InsightInput.hasData] false or an unrecognized phase → [InsightContext.noData].
/// - Menstrual phase: [InsightInput.menstrualDay] (server cycle day while
///   bleeding) picks early (≤2), late (≥3), or unknown (null).
/// - Other phases map directly. No inference, no calculations.
InsightContext contextFor(InsightInput input) {
  if (!input.hasData) return InsightContext.noData;
  switch (input.phase.toLowerCase()) {
    case 'menstrual':
      if (input.menstrualDay == null) return InsightContext.menstrualUnknown;
      return input.menstrualDay! <= 2
          ? InsightContext.menstrualEarly
          : InsightContext.menstrualLate;
    case 'follicular':
      return InsightContext.follicular;
    case 'ovulation':
      return InsightContext.ovulation;
    case 'luteal':
      return InsightContext.luteal;
    default:
      return InsightContext.noData;
  }
}

/// Selects the served pair. Pure and total: every input yields a pair.
InsightPair selectInsightPair(InsightInput input) {
  return insightPairs[contextFor(input)]!;
}

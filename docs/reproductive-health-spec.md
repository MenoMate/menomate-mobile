# MenoMate Reproductive-Health Specification (Phase 0 — Documentation Only)

> Status: **Phase 0 specification. Normative for all future reproductive-health phases.**
> This document specifies product and medical behavior BEFORE any fertility/ovulation,
> pregnancy-mode, or reproductive-aging implementation. It creates no code, no schema,
> no API, and no behavior change.
>
> Source of truth for existing architecture: this repository (`menomate-mobile`) —
> `README.md`, `docs/backend_gaps.md`, `lib/data/app_database.dart` (schema v4),
> `lib/data/repositories/*`, `lib/services/api_service.dart`, `lib/models/*`,
> `lib/providers/*`, `lib/core/device_timezone.dart`, `lib/content/insight_library.dart`.
>
> Backend internals (FastAPI prediction model, prediction ledger, backtest harness,
> Render deployment, backend Health Context migrations) live in `MenoMate_core` and were
> **not** inspected in this phase — see §10 and §12 for the handling rule.

---

## 1. Existing architecture (as built)

### 1.1 Client stack

```text
UI (screens/widgets)
  → Riverpod providers (DataState values)
    → repositories (cycle / daily-log / profile / health-context)
      → Drift/SQLite locally (pending rows) + FastAPI remotely (sync)

Flutter handset <--BLE--> ESP32 wearable (partial: scan works, commands stubbed)
```

- Providers: `currentCycleProvider`, `historySummaryProvider`, `cycleListProvider`,
  `profileProvider`, `healthContextProvider`/`conditionsProvider`/`medicationsProvider`,
  `careSessionProvider`, onboarding/theme/offline-mode providers (`lib/providers/`).
- Repositories: `CycleRepository`, `DailyLogRepository`, `ProfileRepository`,
  `HealthContextRepository` (`lib/data/repositories/`).
- Transport: `ApiService` (Dio + Supabase JWT Bearer interceptor). The app never touches
  Supabase PostgreSQL directly — only FastAPI routes, only its own user's data.
- Local store: Drift/SQLite `menomate.db`, **schema v4**:
  `LocalProfiles` (incl. IANA `timezone`, `birthYear`/`birthMonth` pair),
  `LocalCycles` (ISO `yyyy-MM-dd` text dates, `localId`/`serverId` reconcile),
  `LocalDailyLogs` (+ `LocalSymptoms` children), `PredictionCache`,
  `LocalHealthContext` (singleton), `LocalConditions`, `LocalMedications`.
  (Note: `README.md` still says "schema v2" — stale doc, reported in §12. Code is v4.)

### 1.2 Existing cycle tracking and prediction architecture

- Cycle truth is **observed period starts/ends** (`period_start`, `period_end?`),
  stored date-only, merged server↔local by server id then start date
  (`_mergeServerCycles`). Pending/conflict rows are never silently overwritten.
- **The app performs no prediction or phase math.** `CycleRepository` documents a freeze:
  all predicted/confidence/phase values are verbatim server cache. The only date
  arithmetic on-device is display-only Day N / observed-interval labels
  (`isoDayDifference`), never used for prediction, phase, or confidence.
- `PredictionCache` stores exactly the approved server-computed fields:
  `phase`, `predicted_next_period`, `days_until_next_period`, `prediction_status`,
  `prediction_confidence`, `average_cycle_length`, `average_period_length` (+ `fetchedAt`).
  Home/History/Calendar render these verbatim, including offline.
- Prediction refresh (`_refreshPredictionAfterPush`) runs only when every local row is
  synced; while any row is pending/conflict the server prediction would be stale, so the
  local factual state stands. No local prediction calculation exists anywhere.
- User-entered future-only periods are **not** predictions: assembled view carries
  `predictionConfidence 'None'`, `predictionStatus 'user_logged'`,
  `predictedNextPeriod null`, `predictionSource 'user_logged'` (enforced by tests).
- Averages shown in History ride the shared cache row; local `cycleVariabilityStdDev`
  is always null (server history field not consumed into a local computation).

### 1.3 Existing timezone semantics

- Single canonical IANA zone via the hand-rolled `menomate/timezone` platform channel
  (`lib/core/device_timezone.dart`; Android `TimeZone.getDefault().id`, iOS
  `TimeZone.current.identifier`). No third-party timezone dependency.
- The zone is synced to `profiles.timezone` (offline-safe pending row; null never wipes
  a server value). The server owns "today" and recomputes authoritatively from the
  stored zone once online.
- DATE-only fields travel and store as `yyyy-MM-dd` strings (`toIsoDate`/`parseIsoDate`,
  device-local calendar parts, never UTC-shifted). Numeric offsets and abbreviations are
  never stored (offsets lose DST/history; abbreviations are ambiguous).
- Null/unknown zone means "keep existing value and retry next session" — never UTC,
  never a failure.

### 1.4 Existing production prediction model (mobile-side observable contract)

- Mobile-observable contract only: `CurrentCycleResponse` fields
  (`has_data`, `current_cycle_day`, `phase`, `is_bleeding`, `is_ongoing`,
  `predicted_cycle_length`, `predicted_next_period`, `days_until_next_period`,
  `prediction_status`, `prediction_confidence`, `prediction_source`,
  `average_cycle_length`, `average_period_length`).
- Model internals, the prediction ledger, and the backtest harness live in
  `MenoMate_core` (per `README.md`: "Prediction evaluation needs thousands of resolved
  ledger rows before any model comparison"). **Phase 0 does not describe, constrain, or
  modify the production next-period predictor beyond §11 protection.** Any future
  reproductive estimate must be a *separate, additive* server-computed surface — never a
  silent change to these fields' meaning.

### 1.5 Existing Care safety boundary

- Care output is **advisory text only**; it cannot drive hardware and never performs
  medical reasoning on-device. Tiered deterministic red-flag triage is server-side
  (`POST /api/v1/care/interactions`); the frontend only renders `tier`
  (`info`/`advisory`/`urgent`, unknown falls back to `info`), `actions` (routed by stable
  id, never label substring), `disclaimer`, and the AI-generated marker.
- Every Care bubble carries the backend disclaimer footer, or a safe default
  ("not medical advice" + "MenoMate library") when empty. Urgent tier renders a
  `CLINICAL SAFETY ADVISORY` card that keeps the disclaimer footer (all enforced by
  `test/safety_hardening_test.dart`).
- Session memory is in-memory only: last 4 completed turns, no persistence/IDs/
  timestamps, cleared on new-chat reset and on logout, never restored across restarts.
- The same boundary governs all future reproductive features: no diagnosis, no
  guarantees, no prescriptions/dosages, no treatment claims. Insight library content
  rules (no certainty language, no diagnosis, every substantive claim carries source
  metadata) remain the floor for any future evidence-backed Insight.

### 1.6 Existing offline-first behavior

- Reads serve the local row first, then refresh from server when reachable
  (`Fresh` vs `Cached`/`PendingSync`/`ConflictState`/`Unavailable`/`NoData`).
  A network failure is never represented as `NoData`.
- Writes apply locally as `pending` immediately, then push upstream oldest-first per
  store (`syncAllPending`: single best-effort pass on startup/reconnect, device timezone
  first). Natural keys (`user,log_date`) make retries converge. 400/409/422 mark only
  that row `conflict` and the pass continues; network/5xx stop the pass and retry later;
  401 stops and surfaces auth explicitly, never blindly retried.
- Cached predictions stay displayable until replaced (no TTL expiry).
- Works offline: history, period/wellness logging, Daily Insight, cached predictions,
  retrospective end (device-local dates). Needs network: Care chat, first
  login/onboarding submit, syncing pending rows.
- Sign-out wipes **every** user-scoped local row + cached prediction + in-memory Care
  session. Offline-created rows move into an account only via explicit consented adoption
  (`adoptOfflineData`); local-only tracking rows are never pushed without that consent.
- Health Context rides the same machinery (PUT full-replacement for the singleton;
  tombstoned deletes for conditions/medications; DELETE idempotent on 404) and is wiped
  exactly like everything else. It never reads predictions and never triggers a
  prediction refresh.

### 1.7 Systems that must remain protected

See §11 (normative list). In short: production next-period predictor contract,
prediction ledger, backtest harness, timezone semantics, cycle semantics, Care safety
boundary, Health Context migrations/tables, production database, Render deployment, and
all working Flutter features are frozen with respect to this expansion until their
own future phase explicitly (and separately) touches them.

---

## 2. Reproductive-health architecture (conceptual flow)

```text
Observed data
    ↓
Evidence
    ↓
Estimate
    ↓
Confidence
    ↓
UI
```

Every reproductive value shown in UI must be traceable back through these layers:

1. **Observed data** — facts the user recorded or a clinician established. Never inferred.
2. **Evidence** — observed data interpreted as reproductive signals (e.g. an LH surge is
   evidence *related to* ovulation; it is not an ovulation date).
3. **Estimate** — a model-derived reproductive value (ovulation date, fertile window,
   next period) computed **server-side only**, from evidence plus cycle history.
4. **Confidence** — one of the §4 status states, derived from data sufficiency and
   variability. Confidence gates what the UI may show.
5. **UI** — renders estimates with estimate-wording, confidence-appropriate prominence,
   and the applicable safety copy. The UI never computes estimates or confidence.

### 2.1 Data classification (normative)

**OBSERVED** — user-recorded or device-recorded facts:

- User-recorded period starts (and ends)
- LH test results (as recorded: positive/negative, with date)
- Basal body temperature readings (value + date/time, as recorded)
- Cervical mucus observations (category as recorded, with date)
- Pregnancy test results (as recorded: positive/negative, with date)
- Clinically established pregnancy information (as provided by the clinician/user,
  stored verbatim with its dating source)

**ESTIMATED** — model-derived reproductive values (server-computed, never observed):

- Ovulation date (estimated)
- Fertile window (estimated span)
- Next period (existing production predictor; unchanged by this spec)
- Any other model-derived reproductive value

**CLINICALLY_CONFIRMED** — explicitly clinician-provided information:

- Clinician-established pregnancy dating (EDD and/or gestational age + dating source)
- First-trimester ultrasound dating where applicable
- Any other explicitly clinician-provided information

Rules:

- OBSERVED and CLINICALLY_CONFIRMED are stored verbatim and displayed as what they are.
  They are never "smoothed", reinterpreted, or silently overridden by model output.
- ESTIMATED values are always labeled as estimates (§5) and always carry a confidence
  state (§4). An estimate must never be rendered with the visual or verbal authority of
  an observed fact.
- No ESTIMATED value may ever overwrite or obscure a CLINICALLY_CONFIRMED value.
  On conflict, the clinician value wins and the estimate is suppressed or annotated —
  never the reverse (§6).
- Late period alone is OBSERVED absence of bleeding. It is not evidence of pregnancy
  and never triggers pregnancy inference (§6).

---

## 3. Fertility / ovulation specification

### 3.1 Cycle day 1 semantics

- **Cycle day 1 is the first day of user-recorded menstrual bleeding for that cycle**
  (the recorded `period_start`), in device-local `yyyy-MM-dd` date semantics (§1.3).
- Spotting-only days are not day 1 unless the user records them as a period start;
  the product must not reclassify user-recorded bleeding behind the user's back.
  If a future phase distinguishes spotting from flow, that distinction must itself be
  user-recorded OBSERVED data, never model inference.
- All cycle-day arithmetic is calendar-date based (existing `isoDayDifference`
  semantics), never UTC-shifted datetimes.

### 3.2 Historical cycle interval requirements

- Fertility/ovulation estimates require a history of **completed OBSERVED cycle
  intervals** (start-to-start between consecutive user-recorded period starts).
- A future phase (Phase 1/2) must define the minimum count and recency rules as API
  contract; Phase 0 requires only that:
  - the minimum exists and is explicit,
  - intervals used are observed (never predicted) starts,
  - incomplete/current cycles do not count toward the minimum,
  - the requirement is documented in the API contract, not hidden in client code.

### 3.3 Cycle variability

- Variability is computed server-side from observed intervals. The client must never
  compute it (consistent with the §1.2 freeze).
- Higher variability must widen uncertainty and/or lower confidence — never be silently
  averaged away. The specific variability metric and thresholds are Phase 1/2 contract
  decisions; Phase 0 forbids inventing them here and forbids client-side computation.
- The existing `usual_cycle_days` / `usual_period_days` profile fields (20–45 / 1–12)
  are user-provided onboarding values, not observed history, and must not substitute
  for observed intervals in confidence decisions.

### 3.4 Estimated ovulation

- Ovulation date is **ESTIMATED** (§2.1): a server-computed value from cycle-history
  evidence plus any ovulation-related evidence (LH, BBT, mucus) the user has recorded.
- It must always be presented as an estimate (e.g. "Estimated ovulation day"),
  with its confidence state visible or reachable, and never as a guaranteed date (§H
  of the task / `docs/reproductive-safety-boundaries.md`).
- No ovulation estimate is shown unless the §3.2 minimum-history requirement and any
  evidence-validity rules are satisfied; otherwise `INSUFFICIENT_DATA` (§4).

### 3.5 Estimated fertile window

- The fertile window is **ESTIMATED**: a server-computed span around estimated ovulation.
- Wording is governed by §5 (mandatory "Estimated fertile window"; banned
  safe/unsafe/guaranteed language). Calendar predictions must never be framed as usable
  for contraception or pregnancy prevention.
- The window's derivation (whatever biology-backed method Phase 2 adopts) must be
  documented in the evidence-linked contract at that time. **Phase 0 invents no
  numerical widths, offsets, weights, or formulas.**

### 3.6 Signal semantics (do not conflate)

- **LH is a prospective ovulation-related signal.** A positive LH test suggests ovulation
  *may* follow; it does not confirm ovulation occurred, and a single result must never
  be rendered as an ovulation date.
- **BBT is retrospective evidence that ovulation may have occurred.** A sustained
  post-ovulatory temperature shift can only be assessed *after the fact*; BBT must
  never be presented as predicting ovulation in advance.
- **Cervical mucus is a prospective fertility-related observation.** Fertile-type mucus
  observations are associated with the approaching fertile window; they are
  user-recorded observations, not measurements of ovulation, and must never be rendered
  as confirmation that ovulation happened.
- Absence of any signal is absence of evidence, not evidence of absence: missing LH/BBT/
  mucus data lowers confidence; it never asserts anovulation.

### 3.7 Confidence and suppression behavior

See §4 for the state machine. Summary of required behavior:

- **Insufficient-data behavior:** below minimum history or with unusable evidence, show
  no estimate — an explicit "not enough data yet" state with guidance to keep logging
  (mirroring the existing future-date/no-data honesty pattern).
- **Low-confidence behavior:** show the estimate only with low-confidence presentation:
  de-emphasized, estimate-worded, variability-acknowledging, never prominent or
  definitive.
- **Suppression behavior:** show no estimate at all when a suppression condition holds
  (pregnancy mode active; user-selected contraception/mode context the contract defines
  as suppressing; clinician-confirmed state that supersedes the estimate; evidence the
  contract deems invalidating). Suppression is silent about *why* beyond the approved
  neutral copy — it never implies a medical conclusion.

---

## 4. Estimate status states (normative)

Every reproductive estimate (ovulation, fertile window, and any future model-derived
reproductive value) carries exactly one of:

| State | Meaning | UI behavior |
|---|---|---|
| `AVAILABLE` | Sufficient history + acceptable variability + no suppression | Estimate shown with standard estimate wording |
| `LOW_CONFIDENCE` | Estimate computable but variability/data-quality concerns apply | Estimate shown de-emphasized, with cautious wording and variability acknowledgment |
| `INSUFFICIENT_DATA` | Below minimum history or evidence unusable | No estimate; "not enough data yet" + logging guidance |
| `SUPPRESSED` | A suppression condition holds (pregnancy mode, superseding clinical state, contract-defined suppressor) | No estimate; neutral copy, no medical implication |

Rules:

- The state is computed **server-side** and consumed verbatim by the client (same
  boundary as §1.2: no client-side estimate or confidence math, ever).
- The existing production `prediction_confidence` / `prediction_status` fields keep
  their current meaning for next-period prediction; the §4 states govern the *new*
  reproductive estimates and must be separate contract fields, not redefinitions.
- `SUPPRESSED` must be distinguishable from `INSUFFICIENT_DATA` in the contract (they
  imply different user guidance), even if their visual treatment is similar.
- State transitions are monotonic within a data snapshot: adding suppressive context
  (e.g. activating pregnancy mode) must move estimates to `SUPPRESSED`, never to a
  weaker hiding state that could be misread as "try again later".

---

## 5. Fertile-window safety (wording contract)

Mandatory wording — the product must use estimate-framed language such as:

- "Estimated fertile window"

The product must NOT use:

- "safe days"
- "unsafe days"
- "guaranteed fertile days"
- "guaranteed infertile days"

(and no paraphrase with the same meaning: "risk-free days", "danger days", "100%
fertile/infertile", "you can't get pregnant on…", "you will conceive on…").

- The product must not claim — explicitly or by implication — that calendar predictions
  can guarantee contraception or pregnancy prevention.
- Fertility estimates are estimates and must never be presented as guaranteed dates.
  Every fertile-window surface must carry or link the estimate disclaimer (full text in
  `docs/reproductive-safety-boundaries.md`).
- This wording contract applies to UI strings, Care responses touching fertility,
  Insight content touching fertility, notifications (when they exist), and any exported
  or shared summaries. Tests must enforce the banned phrases exactly as the Insight
  library tests enforce banned certainty language today.

---

## 6. Pregnancy mode

### 6.1 Explicit user-controlled mode

- Pregnancy mode is an **explicit user-controlled mode**: entered and exited by the
  user's own action (e.g. recording that they are pregnant, entering clinician-provided
  dating), never by model inference.
- **A late period must NOT trigger pregnancy inference.** Absence of bleeding is
  OBSERVED absence of bleeding (§2.1). At most, after a contract-defined delay, the
  product may offer a neutral, non-alarming suggestion to log a pregnancy test result
  or consult a clinician — worded as an option, never as a suspicion or conclusion.
  (Exact copy and timing are Phase 3 contract decisions.)
- Recording `pregnancy_context: 'pregnant'` (existing Health Context enum) today
  explicitly **does not change predictions** (`docs/backend_gaps.md`). Pregnancy mode
  as specified here does not exist yet; when Phase 3 builds it, that backend-gaps
  statement is superseded by a new contract — the change must be explicit, reviewed,
  and documented, never a silent behavior flip.
- The system must never automatically change medical modes based solely on model
  inference (normative; see also `docs/reproductive-safety-boundaries.md`).

### 6.2 Suppressions while pregnancy mode is active

When pregnancy mode is active, all ordinary cycle estimation is suppressed:

- Ordinary cycle predictions → suppressed
- Ovulation prediction → suppressed (`SUPPRESSED`)
- Fertile-window prediction → suppressed (`SUPPRESSED`)
- Next-period prediction → suppressed (display and cache handling defined in Phase 3;
  the production predictor itself is unchanged — its output is withheld, not altered)

The pregnancy timeline becomes the primary reproductive context: gestational age,
estimated due date, and trimester-appropriate context replace the cycle ring's
prediction role. Cycle-history data is retained untouched underneath.

### 6.3 Pregnancy timeline contents

- **Gestational age** — computed from the active dating basis, in weeks+days, with the
  dating source shown alongside (never a bare number presented as fact).
- **Estimated due date (EDD)** — labeled "Estimated due date" even when clinician-set.
- **Pregnancy timeline** — trimester/progress context derived from gestational age;
  informational only, no fetal-development guarantees or medical directives.
- **Dating source** — always recorded and always visible: which of the §6.4 hierarchy
  levels the current dating comes from.
- **Clinically established dating** — stored verbatim with source; the authoritative
  basis whenever present.

### 6.4 Dating hierarchy (normative)

1. **Clinically established dating** (clinician-provided EDD/gestational age) — highest
   authority.
2. **First-trimester ultrasound dating** (where applicable) — second authority.
3. **LMP-based estimate** (from user-recorded period starts) — fallback estimate only.

Rules:

- The system must **preserve clinician-established dating rather than silently
  overriding it.** New LMP data, model re-estimates, or later ultrasounds must never
  replace a clinician-established date without explicit user confirmation that names
  the change (old → new, and source).
- LMP-based dating is ESTIMATED and carries the §4 confidence treatment; it must never
  be displayed with the authority of clinician dating.
- The active dating basis and its level must be visible wherever gestational age or
  EDD is shown.

---

## 7. Perimenopause / reproductive-aging context

### 7.1 A contextual layer, not a diagnosis

- Reproductive-aging context is a **CONTEXTUAL layer** over existing cycle data. It
  informs presentation (expectation-setting, cautious estimates) and never produces a
  diagnosis, stage label, or medical conclusion about the user.
- It must be architecturally incapable of diagnosing: a presentation-layer signal with
  no diagnostic output path, reviewed under the same Care safety boundary (§1.5).

### 7.2 Signals the system may monitor

From OBSERVED data and user-reported symptoms only:

- Increasing cycle variability (server-computed from observed intervals)
- Persistent changes in cycle length
- Prolonged gaps between periods
- Bleeding-pattern changes (duration/flow as recorded)
- Relevant user-reported symptoms (sleep, mood, vasomotor symptoms as logged — stored
  verbatim, never interpreted as diagnostic criteria)

All signals are trend-over-time observations requiring sustained patterns; a single
unusual cycle is never meaningful on its own (consistent with the existing Insight
library's ovulation-context copy).

### 7.3 Language contract

The product must NOT state:

- "You are perimenopausal." (nor any paraphrase: stage labels, "you have…",
  "you're in menopause", diagnostic certainty of any kind)

Instead it uses cautious, pattern-describing language such as:

- "Your cycle pattern has become more variable."
- "These changes can occur during the menopausal transition."

— always describing the *pattern*, optionally noting that such patterns *can occur* in
the transition, and directing persistent or concerning changes to a clinician. Full
wording inventory in `docs/reproductive-safety-boundaries.md`.

### 7.4 Effect on fertility estimates

- As reproductive-aging signals increase, fertility estimates must become **more
  cautious**: confidence degrades toward `LOW_CONFIDENCE` / `INSUFFICIENT_DATA` rather
  than continuing to present crisp estimates over increasingly irregular data.
- The exact degradation rule is a Phase 4 contract decision. Phase 0 requires only the
  direction (more variability → less assertive estimates) and the mechanism (the §4
  state machine, computed server-side).

---

## 8. Evidence linkage (summary; registry in `docs/reproductive-evidence-library.md`)

- Every non-trivial reproductive claim in product copy, Care responses, and Insights
  must trace to an entry in the evidence registry (`docs/reproductive-evidence-library.md`).
- The registry records ID, topic, short reviewed claim, source, publication/year, URL
  or identifier, product implication, and limitations. No full papers/PDFs in the app;
  no long copied passages.
- Initial coverage (8 topics, all required): menstrual-cycle physiology, ovulation
  timing, fertile-window biology, fertility-awareness methods, ovulation detection
  methods, pregnancy dating, pregnancy recognition, perimenopause/menopausal transition.
- The Insight library's existing rule — every substantive medical claim carries real
  source metadata — extends to all reproductive content.

---

## 9. Safety boundaries (summary; normative text in `docs/reproductive-safety-boundaries.md`)

MenoMate must NOT:

1. Diagnose medical conditions
2. Diagnose pregnancy automatically
3. Diagnose infertility
4. Diagnose perimenopause
5. Guarantee ovulation dates
6. Guarantee fertile/infertile days
7. Guarantee contraception
8. Guarantee conception
9. Replace clinician-established pregnancy dating
10. Provide unsafe treatment recommendations
11. Automatically change medical modes based solely on model inference

These are restated here for visibility; the binding формулировки, wording inventories,
and enforcement notes live in `docs/reproductive-safety-boundaries.md`.

---

## 10. Future architecture (planned phases)

- **Phase 1 — Backend data model + API contracts.** New server-side tables/endpoints
  for fertility evidence (LH/BBT/mucus/test results as observed data), pregnancy-mode
  state + dating basis, reproductive-aging signals; contract-first, server-computed
  estimates with confidence/source fields. Never client-computed. (Supersedes the
  relevant `docs/backend_gaps.md` entries explicitly, one by one.)
- **Phase 2 — Fertility/ovulation evidence engine.** Server-side Observed→Evidence→
  Estimate→Confidence pipeline per §2–§4; minimum-history and variability rules;
  signal semantics per §3.6; no invented weights/formulas without evidence entries.
- **Phase 3 — Pregnancy mode.** Explicit user-controlled mode per §6; suppression set
  per §6.2; timeline + dating hierarchy per §6.3–§6.4; late-period neutrality rule.
- **Phase 4 — Reproductive-aging context.** Contextual layer per §7; cautious-language
  contract; confidence degradation for fertility estimates.
- **Phase 5 — Flutter UI.** Render server spans with distinct estimate styling + legend;
  pregnancy timeline as primary context in pregnancy mode; perimenopause-aware copy;
  offline-first via the existing repository/DataState machinery. No new local math.
- **Phase 6 — Evidence-backed Insights.** Extend the deterministic Insight library
  pattern to reproductive contexts with evidence metadata; same content rules (no
  certainty/diagnosis/prescription language); optional AI layer stays non-required.
- **Phase 7 — Full regression + real-device validation.** Existing suite
  (`flutter analyze`, `flutter test`) plus new reproductive tests (banned-phrase,
  suppression, dating-preservation, state-machine tests); real-device checks for new
  surfaces as §"Testing"/"Known limitations" require today.

Each phase updates `docs/backend_gaps.md` (or its successor) so the gap list never
silently disagrees with the contract.

---

## 11. Existing-system protection (normative)

Phase 0 — and every later phase except through its own explicit, reviewed change —
MUST NOT modify:

1. Existing production next-period predictor (model, meaning of its contract fields)
2. Prediction ledger
3. Backtest harness
4. Timezone semantics (`menomate/timezone` channel, IANA-only storage, date-only
   handling, server-owns-today)
5. Existing cycle semantics (day-1 = recorded `period_start`, interval/display rules)
6. Care safety boundary (server-side triage, advisory-only rendering, disclaimer
   footer, in-memory session)
7. Existing Health Context migrations/tables (`LocalHealthContext`, `LocalConditions`,
   `LocalMedications`, v3→v4 migration, PUT/tombstone sync contracts)
8. Production database
9. Render deployment
10. Existing working Flutter features (onboarding, Home/History/Care/Settings,
    offline-first sync, Daily Insight library, BLE scan Plumbing as-is)

Conformance: this phase created documentation only — no migrations, no FastAPI/Flutter
code, no tests, no prediction-algorithm, no config, no deployment, no commit/push
changes (verified §13).

---

## 12. Repository conflicts and open questions

1. **Backend not inspected (expected).** The production prediction model, prediction
   ledger, backtest harness, Render deployment, and backend Health Context migrations
   live in `MenoMate_core`, which is outside this workspace. This spec constrains only
   their *mobile-observable contract* and protects them via §11. Phase 1 must reconcile
   this spec against the actual backend before writing contracts. (Instruction
   anticipated this: conflicts are reported, not silently resolved.)
2. **Stale schema version in `README.md`.** README "Local database" says schema v2;
   `lib/data/app_database.dart` declares `schemaVersion => 4` and `docs/backend_gaps.md`
   says "Drift schema v4". README is stale; code (v4) is authoritative. No behavior
   changed; README correction is out of scope for Phase 0 (docs-only constraint covers
   the three specified files).
3. **"Dormant Health Context migrations" (protect list) vs mobile repo state.** In this
   repo the Health Context migration (v3→v4) is active and shipped, with live tables and
   sync. No dormant migrations were found in `menomate-mobile`. The item is interpreted
   as backend-side (`MenoMate_core`) and is protected untouched. Phase 1 to confirm
   against the backend.
4. **Uncommitted working tree.** The repo has extensive uncommitted modifications on
   branch `frontend-development` (plus untracked files). Phase 0 adds only the three
   specified untracked docs and does not stage, commit, or push anything.
5. **Open product questions for Phase 1–4 contracts** (not decided in Phase 0, by design):
   minimum-history counts/recency (§3.2); variability metric and thresholds (§3.3);
   fertile-window derivation method (§3.5); late-period neutral-suggestion timing/copy
   (§6.1); next-period cache withholding mechanics in pregnancy mode (§6.2); aging-signal
   degradation rule (§7.4); notification-surface wording (no notification system exists yet).

---

## 13. Phase 0 verification

- [x] Repository inspected before writing (README, `docs/backend_gaps.md`, Drift schema,
      repositories, providers, models, timezone channel, Insight library, Care boundary,
      tests, git state).
- [x] Created `docs/reproductive-health-spec.md` (this file).
- [x] Created `docs/reproductive-evidence-library.md` (§8 registry).
- [x] Created `docs/reproductive-safety-boundaries.md` (§9 normative boundaries).
- [x] No code, migration, test, config, or deployment artifact touched (documentation
      only; `git status` shows only the three new untracked docs as additions).
- [x] Reviewed for contradictions with existing architecture (§12 reports all found).
- [ ] Phase 1 NOT started. STOP.

# MenoMate Insights — Evidence & Content Architecture Specification (Phase 6A)

> Status: **Phase 6A formal specification. Normative contract for Phase 6B implementation.**
> This document defines the evidence model, content architecture, safety model,
> and implementation boundaries for MenoMate Insights. It creates no code, no
> schema, no API, no prediction change, and no behavior change.
>
> Source of truth for existing architecture: the working trees inspected
> read-only before writing —
> `menomate-mobile` (`lib/content/insight_library.dart`,
> `lib/screens/tabs/insights_tab.dart`, `lib/widgets/daily_insight_card.dart`,
> `lib/models/reproductive.dart`, `lib/data/app_database.dart`,
> `docs/reproductive-health-spec.md`, `docs/reproductive-evidence-library.md`,
> `docs/reproductive-safety-boundaries.md`, `docs/backend_gaps.md`), and
> `MenoMate_core` (`docs/reproductive-backend-contract.md`,
> `app/services/cycle_calculator.py`, `app/services/fertility_estimator.py`,
> `app/services/pregnancy_dating.py`, `app/schemas/fertility.py`,
> `app/api/v1/reproductive.py`).
> Where this specification's phase language differs from the implemented code,
> **current code is authoritative**; discrepancies are recorded in §35, never
> resolved by editing code.
>
> Only this file is created in Phase 6A. No existing document is modified.

---

## 1. Product purpose

### 1.1 What MenoMate Insights is

MenoMate Insights is an **educational reproductive-health content system** in
the spirit of the educational/content experience of apps such as Flo: a
browsable, searchable library of calm, evidence-informed, long-form articles
(plus short explainers), lightly personalized by what the user has recorded,
that helps ordinary users understand their bodies. It covers broader
women's and reproductive health — **not only menstruation and fertility**.

### 1.2 How it must feel

Every Insight article must be:

- **educational** — it teaches; it does not assess, score, or diagnose;
- **evidence-informed** — every non-trivial health claim traces to a claim-registry entry (§7) backed by the source registry (§29);
- **understandable** — plain language first, medical terms introduced gently and defined on first use;
- **calm** — steady tone, no alarm, no urgency except inside explicitly marked red-flag blocks (§27);
- **non-judgmental** — no moral framing of bodies, choices, symptoms, or life circumstances;
- **useful to ordinary users** — actionable self-care and "what to discuss with a clinician" guidance, not academic surveys;
- **capable of contextual personalization** — recorded context may change *priority* (§20), never availability and never conclusions;
- **medically cautious** — uncertainty stated explicitly (§26), never implied away;
- **explicit about uncertainty** — ranges, variability, and "experiences vary" are first-class content, not footnotes;
- **clearly separated from diagnosis** — no article, ranking, visual, or personalization output may function as, or be reasonably mistaken for, a diagnosis (§5, §26).

### 1.3 Long-form structure with visual concepts

Where a topic warrants depth, articles use the long-form schema in §23 with
hero/banner concepts and informational visuals (§24): cycle illustrations,
hormone timelines, fertility-window diagrams, reproductive-aging timelines,
pregnancy-development visuals. Visuals carry information (§24), never
decoration-only authority.

### 1.4 The governing negative

**MenoMate must not become a diagnostic tool merely because it contains
health information.** Breadth of coverage increases this risk, so every
mechanism in this specification (provenance §5, claim registry §7, safety
model §26, review workflow §28, 6B boundaries §33) exists to hold the line:
information in, no diagnoses out.

---

## 2. Source foundation

### 2.1 The supplied research corpus (topic groups)

The content architecture is built for the research corpus already supplied
for MenoMate, covering these source groups:

- menstrual tracking
- fertility-awareness methods
- ovulation detection
- cervical mucus
- basal body temperature
- urinary LH
- fertile-window timing
- conception probability
- PCOS
- endometriosis
- irregular menstruation
- pregnancy physiology
- pregnancy dating
- reproductive aging / perimenopause
- menopause
- fertility preservation
- contraception
- menstrual health and stigma
- sleep and menstrual-cycle effects
- reproductive physiology

Corpus honesty note: **no corpus files (PDFs, papers, extracts) were found in
either repository working tree at spec time** (verified: no `*.pdf` under
`menomate-mobile/` or `MenoMate_core/`; the only evidence artifacts in-repo
are `docs/reproductive-evidence-library.md` and the source metadata in
`lib/content/insight_library.dart`). The architecture therefore treats the
corpus as an **externally held collection keyed to the topic groups above**:
claim entries (§7) cite corpus items by stable source IDs, and any claim whose
corpus item cannot be located at drafting time is marked as a source gap
(§32) instead of being written from memory. **Do not fabricate sources.** If a
claim cannot be supported by the available research corpus or an authoritative
source below, mark it as a source gap instead of inventing evidence.

### 2.2 Already-verified in-repo sources (usable now)

These sources already appear in shipped, tested code and may be cited at
their existing strength without re-verification of existence (claims built on
them still go through the §28 workflow):

| Source | Appears in | Strength |
|---|---|---|
| ACOG patient-education FAQ on dysmenorrhea (`ACOG-FAQ-dysmenorrhea`) | `lib/content/insight_library.dart` (3 pairs) | Guideline-supported patient education |
| Cochrane review (`Cochrane CD004142 (2019)`) | `lib/content/insight_library.dart` (2 pairs) | Systematic review |
| Yuan et al. 2026 systematic review (`DOI 10.3389/fmed.2025.1730505`) | `lib/content/insight_library.dart` (heat for cramps) | Systematic review |
| USDA FoodData Central (`USDA-FDC`) | `lib/content/insight_library.dart` (nutrient-source facts only) | Reference database |
| Phase 0 evidence IDs `EV-PHYS-001` … `EV-PERI-002` | `docs/reproductive-evidence-library.md` | **All NEEDS-REVIEW placeholders** — usable as claim scaffolding only; each must be verified against its cited source before any article relying on it passes clinical review (§28) |

### 2.3 Current authoritative guidance (identified for Phase 6 use)

Where the supplied papers are insufficient for current actionable
recommendations, the following current authoritative sources were already
identified for this program and are the preferred basis for actionable advice.
Full citations (edition, year, URL/DOI) are pinned at drafting time in the
source registry (§29); titles below are given exactly as identified:

1. American Society for Reproductive Medicine (ASRM) — "Optimizing Natural Fertility: A Committee Opinion"
2. American College of Obstetricians and Gynecologists (ACOG) — "Evaluating Infertility"
3. ACOG — "Methods for Estimating the Due Date"
4. ACOG — "When Pregnancy Goes Past Your Due Date"
5. ACOG — "Do I Need Hormone Testing During Perimenopause?"
6. ACOG — "How Aging Affects Fertility and Pregnancy"
7. ACOG — "Prepregnancy Counseling"

These are **guidance sources, not individual clinical confirmation** (§3, §5):
they license what the product may teach populations, never what it may
conclude about a user.

### 2.4 Sourcing rules

1. Prefer current guidelines and systematic reviews over single studies; prefer
   the §2.3 list for actionable recommendations.
2. Never present a manufacturer claim (e.g. test-kit marketing) as independent evidence (§25).
3. Never reuse historical effectiveness numbers as if current (§18).
4. Historical sources are retained with `HISTORICAL_CONTEXT` status (§3) for
   provenance, never silently used as current guidance (§29).
5. Every article's claims resolve to registry entries; an unresolvable claim
   is a source gap (§32), and the article ships without that claim.

---

## 3. Evidence taxonomy

Each claim carries exactly one `evidence_status`. These describe **the state
of the evidence behind a statement** — they say nothing about any individual
user.

### 3.1 The seven categories (normative definitions)

- **`RESEARCH_SOURCE`** — The statement is supported by one or more
  peer-reviewed research publications (cohort, case–control, observational, or
  experimental studies) that a curator has read and recorded. It does **not**
  imply guideline endorsement, consensus, or clinical applicability to any
  individual. Scope of license: descriptive/associational statements only
  ("X is associated with Y in population Z").
- **`GUIDELINE_SUPPORTED`** — The statement is consistent with a current
  guideline or professional-society patient-education position (e.g. ACOG
  FAQ-level consensus used in the shipped Insight library). Stronger than a
  single study; still population-level. Scope of license: standard
  educational statements and conservative self-care options.
- **`CURRENT_GUIDANCE`** — The statement reflects *current, actionable*
  clinical guidance from an authoritative body (normally the §2.3 list),
  verified against the current edition at review time. This is the **only**
  status that licenses actionable recommendations ("consider discussing X",
  "Y is generally recommended"), red-flag thresholds (§27), and
  effectiveness/eligibility/contraindication content (§18). Requires
  `currentness = current` in the source record (§29).
- **`MIXED_EVIDENCE`** — Credible sources exist on more than one side, or
  effect sizes differ meaningfully across populations/settings, with no
  authoritative resolution. The article **must present the disagreement**
  ("studies differ…") and must not pick a winning side for the user.
- **`LIMITED_EVIDENCE`** — The evidence base is thin (small samples, single
  small studies, indirect populations, or plausible-mechanism-only). The
  article must hedge explicitly ("early or limited evidence suggests…"),
  must not carry actionable recommendations on this basis, and must name the
  limitation in plain language.
- **`CONFLICTING_EVIDENCE`** — Sources directly contradict each other on the
  point in question (stronger than `MIXED_EVIDENCE`: not variation but
  opposition). The article must state the conflict, must not resolve it, and
  must direct decisions to a clinician.
- **`HISTORICAL_CONTEXT`** — The statement describes what was believed,
  practiced, or published in the past (e.g. older effectiveness figures,
  superseded methods). Usable only in explicitly historical passages
  ("In the past…; current guidance differs…"). **Never usable as current
  advice**, even paraphrased.

### 3.2 The load-bearing distinction

**Evidence status is NOT clinical confirmation.** A peer-reviewed study
supporting a statement does not mean that a particular user's condition is
clinically confirmed. Concretely:

- `RESEARCH_SOURCE` (or stronger) on "PCOS is associated with irregular
  cycles" does **not** license "your irregular cycles indicate PCOS" — the
  first is a population claim, the second would be an individual clinical
  inference, which is prohibited (§12, §26).
- Evidence status travels with the *claim*; clinical confirmation travels
  with the *user's record* via the `CLINICALLY_CONFIRMED` provenance layer
  (§5), which content can never create.

---

## 4. Clinical review status

### 4.1 The field

Each claim carries a separate `clinical_review_status` with exactly two values:

- **`NOT_CLINICALLY_REVIEWED`** — default for all new/draft claims.
- **`CLINICALLY_REVIEWED`** — a qualified clinical reviewer has verified the
  claim's medical accuracy, wording, diagnostic boundaries, and citations per
  the §28 checklist, recorded with reviewer identity (role-level, e.g.
  "reviewing clinician") and `reviewed_at` date.

### 4.2 Why it must remain separate from evidence status

Evidence status answers "how strong is the science?"; clinical review answers
"has a clinician verified *this use of the science in this article*?" These
vary independently:

- A paper may provide strong research evidence (`GUIDELINE_SUPPORTED`) but
  the specific MenoMate article using it may still be awaiting clinical
  review (`NOT_CLINICALLY_REVIEWED`) — e.g. wording not yet checked for
  diagnostic implication.
- Conversely, a clinician may review and *restrict* a well-evidenced claim
  ("accurate but too easily misread — soften and add red-flag block").

### 4.3 Rules

- **Do NOT label content `CLINICALLY_CONFIRMED` merely because research
  supports it.** `CLINICALLY_CONFIRMED` is a *provenance* value about a
  user's clinical facts (§5), never a content-review badge. Confusing the two
  is a blocking defect.
- Publication (§31) requires `CLINICALLY_REVIEWED` on every non-trivial
  health claim in the article; `NOT_CLINICALLY_REVIEWED` claims block the
  `CLINICAL_REVIEW → PUBLISHED` transition.
- Review is per claim-in-article, not per source: reusing a reviewed claim in
  a new article with new surrounding wording requires re-review of the claim
  in its new context.

---

## 5. Provenance model

Four distinct provenance layers. Every piece of data, estimate, statement, or
visual in Insights resolves to exactly one.

### 5.1 Definitions

- **`EVIDENCE_SUPPORTED`** — A statement supported by research or guidelines
  (a claim-registry entry, §§3–4, 7). Lives in article content. Says what is
  generally true; says nothing about the reader.
- **`OBSERVED`** — Information explicitly recorded by the user (period
  starts/ends, symptoms, moods, LH/BBT/mucus rows, notes, health-context
  selections) or device-recorded facts. In the implemented architecture these
  are the local-first rows (`LocalCycles`, `LocalDailyLogs` + `LocalSymptoms`,
  `LocalFertilityObservations`, health tables) synced with the FastAPI
  backend. Displayed verbatim, never reinterpreted.
- **`ESTIMATED`** — A value or interpretation calculated by MenoMate from
  recorded data: the frozen next-period prediction (`robust_wma_v1`,
  `prediction_confidence`/`prediction_status`), the Phase 2 fertility
  estimate (`fertility_v1` 1.0.0, statuses `AVAILABLE` / `LOW_CONFIDENCE` /
  `INSUFFICIENT_DATA` / `SUPPRESSED`, `evidence_source` `OBSERVED` /
  `ESTIMATED` / `CLINICALLY_CONFIRMED`), gestational-age derivations from the
  stored dating basis. Always labeled as estimates with the applicable
  disclaimer; never silent.
- **`CLINICALLY_CONFIRMED`** — A diagnosis, condition, pregnancy status,
  dating result, or other clinical fact explicitly supplied or established by
  an appropriate clinician or clinical record (e.g. clinician-established EDD
  with `dating_source = clinician`, user-recorded clinician-given diagnosis
  stored verbatim as the user's statement of their care). Content can display
  such facts when the record contains them; content can never create them.

### 5.2 Rules (normative)

1. **Observed data is not a diagnosis.** Logged pain, however severe or
   repeated, is a record of pain. Personalization may surface pain education
   (§21); it may never name a condition.
2. **Estimated data is not clinical confirmation.** A fertile-window estimate,
   however confident, is not confirmation of ovulation, fertility, or
   infertility (§10, §11).
3. **Research evidence is not individual clinical confirmation.** Population
   claims (§3.2) never bridge to a reader without a clinician.
4. **MenoMate must never upgrade provenance automatically.** No pipeline —
   personalization (§20–§22), ranking, review, or rendering — may promote
   `OBSERVED → ESTIMATED → CLINICALLY_CONFIRMED`, relabel `ESTIMATED` with
   the authority of `OBSERVED`, or present `EVIDENCE_SUPPORTED` as though it
   described the reader. Promotion requires an explicit, attributable source:
   a new user recording (→ `OBSERVED`), a new server computation
   (→ `ESTIMATED`), or a clinician/clinical record (→ `CLINICALLY_CONFIRMED`).
5. Downgrade is always allowed: any surface may present a higher-provenance
   item with *less* authority (e.g. quoting a clinician date as "the date you
   recorded from your clinician"), never more.

---

## 6. Complete topic taxonomy

Ten top-level categories. Each entry gives purpose, example subjects,
suitable article types, personalization signals (priority-only, §20), and
safety considerations. Slugs in parentheses are the proposed stable category
keys for Phase 6B.

### 6.1 Menstrual Cycle (`menstrual-cycle`)

- **Purpose:** teach cycle literacy — what a cycle is, what varies normally, and how the app's own conventions (Day 1, phases) work.
- **Example subjects:** cycle Day 1 convention; cycle-length variation within and between people; follicular and luteal phases; hormonal changes across the cycle; irregular bleeding and its broad cause categories; when persistent abnormal patterns merit medical discussion.
- **Suitable types:** explainer, timeline, myth-vs-fact, checklist ("what to track"), when-to-seek-care.
- **Personalization signals:** recent period start (recency), cycle variability band (computed server-side; coarse bands only, never raw scores), thin history (onboarding to tracking articles).
- **Safety:** Day-1 and phase language must match app conventions exactly; variability language must stay pattern-describing; no per-day feeling predictions (§19).

### 6.2 Ovulation & Fertility (`ovulation-fertility`)

- **Purpose:** teach how ovulation relates to fertility and what each marker can and cannot say.
- **Example subjects:** what ovulation is; LH testing; BBT; cervical mucus; calendar-based estimation; clinical detection (ultrasound/hormonal); marker-vs-confirmation distinction (§9); how ovulation estimates work; the fertile window; TTC timing and cycle awareness.
- **Suitable types:** explainer, comparison (marker table), diagram (window schematic — informational, never a personal calendar), myth-vs-fact.
- **Personalization signals:** recorded LH/BBT/mucus rows (surface the matching marker article), current estimate status band (`AVAILABLE` → estimate literacy; `INSUFFICIENT_DATA` → logging guidance).
- **Safety:** §9–§11 in full; banned language enforced (§10); signal semantics from the safety boundaries (LH prospective-related, BBT retrospective, mucus prospective observation — never confirmation).

### 6.3 Cycle Tracking (`cycle-tracking`)

- **Purpose:** make users good trackers — the skill the whole product depends on.
- **Example subjects:** what to log and when; logging promptly vs reconstructing; editing past entries; future-entry honesty; offline logging and sync; spotting vs period starts (user-recorded distinction only); symptom-logging habits.
- **Suitable types:** checklist, how-to, short explainer.
- **Personalization signals:** thin history, gaps in logging, frequent edits (surface gently, once — never nagging loops).
- **Safety:** low-risk category, but must never promise that better tracking yields exact predictions; tracking improves *inputs*, and uncertainty remains.

### 6.4 Symptoms & Wellbeing (`symptoms-wellbeing`)

- **Purpose:** normalize and explain common cycle-adjacent experiences without medicalizing them.
- **Example subjects:** pain, mood, sleep, appetite, energy, bloating, headaches, breast symptoms, skin changes, general wellbeing.
- **Suitable types:** explainer, self-care options, myth-vs-fact, when-to-seek-care.
- **Personalization signals:** logged symptom frequencies (counts only — the existing `_SymptomPatternsCard` aggregate, never interpreted), current phase band.
- **Safety:** §19 — population language only ("some people notice…"), never deterministic day→feeling statements; symptom clusters must never resolve to conditions (§12–§14).

### 6.5 Reproductive Health (`reproductive-health`)

- **Purpose:** condition literacy for diagnoses a clinician might discuss — what they are, in general, at population level.
- **Example subjects:** PCOS; endometriosis and pelvic pain; thyroid health and the cycle; other differential categories (§14); when period changes are worth discussing.
- **Suitable types:** explainer, comparison ("these conditions can share symptoms — only a clinician can distinguish them"), when-to-seek-care, checklist ("what to bring to an appointment").
- **Personalization signals:** user-supplied health conditions/medications (surface matching literacy content as *information the user asked about by recording it* — never as suspicion), repeated severe pain logs (surface pain education per the §21 example, never a condition article framed as an answer).
- **Safety:** §§12–14; the "can occur in…" pattern language; no symptom-to-diagnosis engine; differential categories taught as clinician territory.

### 6.6 Pregnancy (`pregnancy`)

- **Purpose:** pregnancy education strictly separated from pregnancy *state* (§15): how dating works, what early pregnancy involves, what due dates mean, symptoms and when to seek care.
- **Example subjects:** how pregnancy dating works; early-pregnancy changes; understanding the due date; pregnancy symptoms and when to seek care.
- **Suitable types:** explainer, timeline (gestational-age informational, no fetal-development guarantees), when-to-seek-care (with red-flag blocks §27).
- **Personalization signals:** **only** explicitly established pregnancy state through the Phase 3 architecture when it exists in the implementation (§35 notes current code state); never lateness, symptoms, or estimates. Without explicit state, these articles are library-only (browsable, never pushed).
- **Safety:** §§15–16; dating hierarchy; no EDD math in content; no "you may be pregnant" inference anywhere; positive-test restraint (confirm with a clinician).

### 6.7 Pregnancy & Body (`pregnancy-body`)

- **Purpose:** the bodily experience companion to §6.6 — physical and practical changes, distinct from dating/medical content so readers can choose their depth.
- **Example subjects:** body changes by stage (informational ranges, not promises); comfort measures with evidence-appropriate hedging; activity/rest guidance only where current guidance supports it; postpartum recovery basics (source-gap prone — see §32).
- **Suitable types:** explainer, checklist, timeline.
- **Personalization signals:** same gating as §6.6 (explicit state only).
- **Safety:** no week-by-week fetal-development guarantees; no medical directives ("you must…"); red-flag blocks wherever symptoms are discussed.

### 6.8 Reproductive Aging (`reproductive-aging`)

- **Purpose:** transition literacy — what perimenopause/menopause are as life stages, how cycles often change, what is known about fertility with age.
- **Example subjects:** what happens during perimenopause; understanding menopause; how reproductive aging affects cycles; fertility and age; hormone-testing limitations.
- **Suitable types:** explainer, timeline (transition as multi-year variability, per STRAW+-style staging *described*, never applied), myth-vs-fact, when-to-seek-care.
- **Personalization signals:** recorded age band (from `birth_year`/`birth_month`, coarse bands only), sustained variability patterns (server-computed trends → expectation-setting content, never stage labels).
- **Safety:** §17; banned stage-label language from the safety boundaries ("You are perimenopausal" and paraphrases); no individual fertility probabilities without a validated, reviewed model; age alone never becomes a fertility prediction.

### 6.9 Contraception (`contraception`)

- **Purpose:** contraceptive literacy under a dedicated safety class (§18).
- **Example subjects:** barrier methods; hormonal contraception; long-acting reversible contraception; emergency contraception; fertility-awareness methods and their limitations.
- **Suitable types:** explainer, comparison (method summaries without league tables of stale numbers), myth-vs-fact.
- **Personalization signals:** recorded `contraception_method` (surface matching literacy content), `fertility_awareness` selection (surface the limitations article, not encouragement).
- **Safety:** §18 — effectiveness/eligibility/contraindications only from current authoritative sources; MenoMate predictions are NOT contraception, stated in every fertility-adjacent article; the app never presents itself as a certified fertility-awareness or contraceptive method.

### 6.10 Mind, Society & Health (`mind-society-health`)

- **Purpose:** the human context — stress, sleep, stigma, and social factors around menstrual and reproductive health.
- **Example subjects:** sleep and the cycle; stress and cycle changes; menstrual health without stigma; talking to clinicians, partners, workplaces.
- **Suitable types:** explainer, self-care options, myth-vs-fact.
- **Personalization signals:** logged sleep/mood patterns (counts only), general engagement (these are safe default recommendations for thin-data users).
- **Safety:** no causal claims about an individual's stress causing their cycle changes (bidirectional, confounded — `LIMITED_EVIDENCE`/`MIXED_EVIDENCE` at best); stigma content must stay non-judgmental and culturally humble; no mental-health diagnosis content (out of scope — signpost professional support where relevant without diagnosing).

---

## 7. Claim registry

### 7.1 Schema (normative)

Each claim entry contains exactly these fields:

| Field | Meaning |
|---|---|
| `claim_id` | Stable ID (`CLM-<DOMAIN>-<NNN>`). Never reused; corrections append dated notes. |
| `topic` | One of the §6 category slugs. |
| `statement` | The precise, self-contained sentence the product may teach (1–2 sentences, paraphrased, no copied passages). |
| `evidence_status` | One of §3 (§3.1). |
| `source_ids` | Registry IDs from §29 (`SRC-…`) and/or Phase 0 `EV-…` IDs. Empty ⇒ source gap: the claim must not ship as content. |
| `evidence_summary` | 1–3 sentences on what the sources actually show. |
| `limitations` | Why the claim licenses nothing stronger (population, design, size, indirectness). |
| `population` | Who was studied (or "general patient-education consensus" / "guideline population"). |
| `date/context` | Source edition/year and any time-sensitivity ("verify current edition"). |
| `personalization_allowed` | Boolean: may recorded user data prioritize (never conclude from) this claim? |
| `individual_inference_allowed` | Boolean: almost always **false**. `true` requires `CURRENT_GUIDANCE` + clinical review + an explicitly approved inference rule recorded here. |
| `clinical_review_status` | §4 (`NOT_CLINICALLY_REVIEWED` default). |

Registry rules: additions require all fields; new claims default to
`NOT_CLINICALLY_REVIEWED`; `individual_inference_allowed: true` is forbidden
unless the §28 clinical reviewer signs the inference rule in the entry.

### 7.2 Representative claim entries (major domains)

> These entries are **illustrative scaffolding for the Phase 6B registry
> seed**, not approved content. All are `NOT_CLINICALLY_REVIEWED`. Entries
> citing `EV-…` IDs inherit their NEEDS-REVIEW status: each must be verified
> against its cited source before any article relying on it passes review.
> Entries with empty `source_ids` are **source gaps** (§32), not claims.

- **`CLM-CYC-001`** · `menstrual-cycle` · "A menstrual cycle is counted from the first day of one period to the day before the next period begins." · `GUIDELINE_SUPPORTED` · sources: `EV-PHYS-001` (NEEDS-REVIEW), `SRC-ACOG-MENST-ED` (to be pinned) · Summary: standard cycle-definition consensus in patient-education guidance. · Limitations: educational definition, not a measurement protocol; spotting-vs-bleeding edge cases are user-recorded. · Population: general. · Context: living guidance, verify edition. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-CYC-002`** · `menstrual-cycle` · "Cycle length varies between people and between cycles in the same person; single unusual cycles are usually not meaningful on their own." · `RESEARCH_SOURCE` · sources: `EV-PHYS-001`, `EV-OVUL-001` (both NEEDS-REVIEW) · Summary: variability-cohort literature plus existing shipped Insight copy. · Limitations: distributions do not predict any individual's cycle. · Population: cohort populations TBD at verification. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-CYC-003`** · `menstrual-cycle` · "The follicular (pre-ovulatory) portion accounts for most cycle-length variability; the luteal portion is relatively less variable." · `RESEARCH_SOURCE` · sources: `EV-PHYS-002` (NEEDS-REVIEW) · Summary: reproductive-endocrinology review consensus. · Limitations: population tendency with wide individual spread; licenses no day-count rules. · personalization: false · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-OVU-001`** · `ovulation-fertility` · "A positive urinary LH test indicates a hormonal surge that often precedes ovulation, but it does not confirm that ovulation occurred." · `RESEARCH_SOURCE` · sources: `EV-DETECT-001` (NEEDS-REVIEW) · Summary: ovulation-detection literature; surge-to-ovulation timing varies; not every surge is followed by ovulation. · Limitations: test sensitivity/timing; conditions such as PCOS-related LH patterns limit interpretation. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-OVU-002`** · `ovulation-fertility` · "A sustained basal-body-temperature rise can be consistent with ovulation having already occurred; it cannot predict ovulation in advance." · `RESEARCH_SOURCE` · sources: `EV-DETECT-002` (NEEDS-REVIEW) · Summary: BBT literature; retrospective marker requiring repeated correct measurement. · Limitations: confounded by illness, sleep disruption, alcohol, measurement error; single readings uninterpretable. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-OVU-003`** · `ovulation-fertility` · "Fertile-type cervical mucus observations are associated with the approaching fertile window; they are subjective observations, not measurements of ovulation." · `RESEARCH_SOURCE` · sources: `EV-DETECT-003` (NEEDS-REVIEW) · Summary: mucus/fertility-awareness literature. · Limitations: subjective categorization; inter-user variability. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-OVU-004`** · `ovulation-fertility` · "Calendar timing alone cannot fix ovulation to a single day for all users, and irregular histories make calendar estimates less reliable." · `RESEARCH_SOURCE` · sources: `EV-OVUL-001`, `EV-OVUL-002` (NEEDS-REVIEW) · Summary: cycle-variability literature. · Limitations: supports the direction (variability → uncertainty), not thresholds. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-FER-001`** · `ovulation-fertility` · "Conception probability is concentrated in an approximately six-day interval ending on the day of ovulation, reflecting sperm survival over several days and short egg viability; individual ovulation timing varies." · `GUIDELINE_SUPPORTED` · sources: `SRC-ASRM-OPTIMIZING-FERTILITY` (to be pinned at drafting), `EV-FERT-001` (NEEDS-REVIEW) · Summary: ASRM committee-opinion concept plus conception-probability cohorts. · Limitations: population probabilities; no per-user guarantees; window width is an educational approximation, not a personal schedule. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-FER-002`** · `contraception` · "Calendar/rhythm-type approaches that rely on past cycle lengths alone are among the least reliable ways to avoid pregnancy and must not be used as contraception." · `GUIDELINE_SUPPORTED` · sources: `EV-FERT-002` (NEEDS-REVIEW; CDC guidance to be pinned) · Summary: contraceptive-effectiveness literature. · Limitations: licenses only the negative claim; no efficacy numbers ship from this entry. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-PCOS-001`** · `reproductive-health` · "PCOS is a common condition associated with irregular cycles and androgen-related and metabolic features; its symptoms overlap with other conditions, and tracking data alone cannot diagnose it." · `LIMITED_EVIDENCE` (pending corpus verification) · sources: *(gap — corpus PCOS item + current PCOS guidance to be pinned, §32)* · Summary: placeholder pending source pinning. · Limitations: everything — do not draft the article until sources are pinned. · personalization: true (pattern-language only) · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-ENDO-001`** · `reproductive-health` · "Endometriosis involves tissue similar to uterine lining growing outside the uterus and is associated with pelvic pain; pain tracking alone cannot diagnose it." · `LIMITED_EVIDENCE` (pending corpus verification) · sources: *(gap — corpus endometriosis item + current guidance to be pinned, §32)* · Summary: placeholder pending source pinning. · Limitations: everything — do not draft until pinned. · personalization: true (pain-education only) · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-PREG-001`** · `pregnancy` · "First-trimester ultrasound measurement is the most accurate single method for establishing gestational age and due date, and is preferred over LMP-based dating when available." · `GUIDELINE_SUPPORTED` · sources: `EV-DATE-001` (NEEDS-REVIEW), `SRC-ACOG-DUE-DATE-METHODS` (to be pinned) · Summary: ACOG dating guidance. · Limitations: assumes clinical measurement quality; precision degrades with later measurement; licenses hierarchy only, no app-side math. · personalization: false · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-PREG-002`** · `pregnancy` · "A missed period is a common reason to consider pregnancy testing but is nonspecific; many other factors also cause late or missed periods." · `RESEARCH_SOURCE` · sources: `EV-PREG-001` (NEEDS-REVIEW) · Summary: clinical pregnancy-diagnosis references. · Limitations: licenses restraint only (what the product must not conclude). · personalization: false (must never trigger inference surfacing) · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-AGE-001`** · `reproductive-aging` · "The menopausal transition unfolds over years with increasing cycle variability and persistent bleeding-pattern changes; staging systems define stages by bleeding-pattern criteria, not by any single cycle." · `RESEARCH_SOURCE` · sources: `EV-PERI-001` (NEEDS-REVIEW; STRAW+/NAMS guidance to be pinned) · Summary: staging-criteria literature. · Limitations: clinical staging tools need history a consumer app cannot fully establish; no staging logic licensed. · personalization: true (expectation-setting only) · inference: false · `NOT_CLINICALLY_REVIEWED`.
- **`CLM-SLP-001`** · `mind-society-health` · "Good sleep supports coping with menstrual discomfort before and during bleeding." · `GUIDELINE_SUPPORTED` · sources: `SRC-ACOG-DYSMENORRHEA-FAQ` (already shipped in-app) · Summary: ACOG dysmenorrhea patient education, already serving in the Daily Insight library. · Limitations: general guidance; no dose/duration prescription. · personalization: true · inference: false · `NOT_CLINICALLY_REVIEWED` (shipped copy grandfathered under existing tests; reuse in long-form requires review).

---

## 8. Menstrual-cycle claims

Minimum coverage (each becomes one or more §7 entries before drafting):

1. **Cycle Day 1 convention** — first day of user-recorded menstrual bleeding; matches the implemented `period_start` semantics and the app's date-only handling. Spotting is not Day 1 unless the user records it as a start; the product never reclassifies bleeding.
2. **Cycle-length variation** — between people and between cycles; single unusual cycles not meaningful alone (consistent with shipped ovulation-context copy).
3. **Follicular and luteal phases** — what each phase is; follicular variability drives most length differences; educational phase labels only.
4. **Hormonal changes across the cycle** — general,audience-level description; **no hormone-mechanism claims** that imply treatment effects (extends the Insight library rule); no dosages, no "X treats Y".
5. **Why calendar regularity does not guarantee exact ovulation timing** — regular past cycles narrow but do not fix ovulation day; bridges to §9.
6. **Irregular bleeding** — what counts as irregular in general terms (persistent pattern language, never thresholds invented in content — any numeric cutoffs require `CURRENT_GUIDANCE` sources).
7. **Common cause categories** — stress, illness, weight change, travel, contraception changes, thyroid and other endocrine causes, PCOS, perimenopause transition, pregnancy possibility (as a *reason to consider testing*, never a conclusion) — taught as *categories a clinician considers*, never a checklist the user self-scores.
8. **When persistent abnormal patterns may warrant medical discussion** — severe/heavy/prolonged bleeding, bleeding between periods, sudden major change, fainting-level symptoms → red-flag block (§27) + "what to bring" checklist.

**Do not convert symptom patterns into diagnoses.** Every article in this domain ends with the pattern-language guard: describes patterns, notes what such patterns *can occur in*, directs persistent/concerning change to a clinician.

---

## 9. Ovulation claims

Minimum coverage:

1. **LH testing** — what the strip detects (surge), prospective-related signal semantics; timing/frequency basics at patient-education level; PCOS-related interpretation limits.
2. **BBT** — retrospective-only semantics; correct-measurement basics (resting, consistent timing); confounders (illness, sleep disruption, alcohol, error); single readings uninterpretable.
3. **Cervical mucus** — prospective fertility-related observation; the app's dedicated scale is distinct from the daily-log discharge volume scale (never conflated — matches the implemented backend split: `ObservationTypeEnum` mucus categories vs `DischargeEnum` volume scale).
4. **Calendar-based estimation** — history-based inference, its uncertainty, and why it degrades with irregularity; the app's own estimate and its confidence states as the worked example.
5. **Ultrasound/hormonal clinical detection** — what clinicians can use (follicle tracking, hormonal confirmation) at literacy level; these are clinical procedures, described not prescribed.
6. **Limitations of each marker** — every marker article carries a limitations section; no marker stands alone as an answer (matches `EV-FAM-001` direction).
7. **Observing signs vs confirming ovulation** — the load-bearing distinction, stated verbatim in each article:

> "A marker *associated with* ovulation" (LH surge, temperature shift,
> fertile-type mucus, calendar position) is evidence *related to* ovulation.
> *"Clinical confirmation of* ovulation" is established only by appropriate
> clinical means. MenoMate records the first; it never provides the second.

---

## 10. Fertile window / TTC

### 10.1 The educational model

- The fertile window is taught as **approximately the six-day interval ending
  on the day of ovulation** (ASRM "Optimizing Natural Fertility" concept,
  `CLM-FER-001`), presented as a population-level educational approximation
  with explicit individual-variation framing: "your ovulation day varies
  cycle to cycle, so no calendar can place this window exactly for you."
- **Sperm survival** (several days) and **egg lifespan** (short — roughly a
  day) are taught as the *reason* the window has a multi-day shape with
  non-uniform probability, without numeric precision the sources do not support.
- **Timing of intercourse** for trying to conceive is taught in general terms
  per current guidance (frequency across the window rather than single-day
  targeting), with uncertainty stated.
- **LH testing, cervical mucus, BBT, calendar estimates** are taught with
  their §9 semantics; uncertainty in predicted ovulation is a required
  section, not an aside.
- MenoMate **may educate about fertility awareness** as a body-literacy
  practice (observing signs, understanding cycles). It must simultaneously
  teach its limitations for avoiding pregnancy (§18, `CLM-FER-002`).

### 10.2 Contraception boundary (normative)

MenoMate **must NOT present its prediction as contraception.** Never use —
in articles, visuals, examples, FAQs, or metadata — language such as:

- "safe days", "unsafe days"
- "guaranteed prevention", "proof of non-fertility"
- "guaranteed ovulation", "guaranteed conception"
- paraphrases with the same meaning ("risk-free days", "danger days",
  "you can't get pregnant on…", "100% fertile/infertile")

The app must explicitly communicate, on every fertility-estimate-adjacent
article, that **fertility estimates are estimates and are not
contraception** (extends the safety-boundaries wording inventory and the
fixed estimate disclaimer to long-form content; enforced by 6B tests per
§33).

---

## 11. Fertility prediction boundary

### 11.1 The two predictors (as implemented — read-only description)

- **Production next-period predictor (FROZEN):** `app/services/cycle_calculator.py`
  (`predict_next_cycle`, median + MAD outlier rejection, recency-weighted
  mean, 20–45 clamp), identity `BASELINE_METHOD = "robust_wma_v1"`
  (`app/services/prediction_ledger.py:21`), evaluated by the walk-forward
  `app/services/backtest.py` harness, served via `GET /api/v1/cycles/current`
  and `GET /api/v1/summary/current`. Mobile consumes it verbatim into
  `PredictionCache`; the client performs no prediction math.
- **Phase 2 fertility estimator (SEPARATE):** `app/services/fertility_estimator.py`,
  identity `FERTILITY_METHOD = "fertility_v1"`, `FERTILITY_METHOD_VERSION =
  "1.0.0"`, pipeline OBSERVED DATA → EVIDENCE → ESTIMATE → CONFIDENCE,
  statuses `AVAILABLE` / `LOW_CONFIDENCE` / `INSUFFICIENT_DATA` / `SUPPRESSED`,
  per-row `evidence_source` (`OBSERVED` / `ESTIMATED` / `CLINICALLY_CONFIRMED`),
  served read-only via `GET /api/v1/reproductive/estimates`
  (`app/api/v1/reproductive.py`), modeled mobile-side in
  `lib/models/reproductive.dart` (`FertilityEstimate`, `hasDates` gating).

### 11.2 Frozen list (normative — Phase 6A and 6B)

Do not modify, retune, re-derive, or reimplement in content or code:

- `app/services/cycle_calculator.py`
- the `robust_wma_v1` method identity and ledger semantics
- the prediction ledger (`app/models/prediction_ledger.py`, `app/services/prediction_ledger.py`)
- the existing backtest harness (`app/services/backtest.py`)
- the `fertility_v1` estimator mathematics, thresholds, and status-gating logic

### 11.3 Content rules following from the boundary

- Fertility estimates are described as **separate from** the frozen cycle predictor: different method, different question (fertile window vs next period), different confidence states. Articles must never imply one validates the other.
- **Do not create** new medical thresholds, weights, confidence scores, or unsupported fertility algorithms in Phase 6A (this document), and 6B must not either (§33). Numbers appearing in articles (e.g. the six-day educational window) are *taught population concepts with cited sources*, never operational parameters.
- Content may explain *how to read* an estimate status (what `LOW_CONFIDENCE` means, why `SUPPRESSED` hides dates) — that is literacy about existing behavior, not new logic.

---

## 12. PCOS

### 12.1 Coverage (literacy, not workup)

- What PCOS is (population-level description, pinned sources only).
- Cycle irregularity as a commonly associated feature.
- Androgen-related features (acne, hair changes) described generally.
- Metabolic associations at literacy level.
- Fertility implications in general terms (links to infertility-evaluation guidance, §32 gap until pinned).
- Why symptoms overlap with other conditions (thyroid disorders, hyperprolactinemia, and others per §14) — the central reason tracking cannot distinguish them.
- **Why tracking data cannot diagnose PCOS** — required section: diagnosis requires clinical evaluation (history, examination, labs/imaging as the clinician judges); app records contain no such evaluation.

### 12.2 Prohibited language (normative)

No article, personalization intro, visual, or metadata may tell — or imply to
— a user **"You have PCOS"** (or paraphrases: "your pattern means PCOS",
"likely PCOS", "consistent with PCOS *in your case*") based only on
irregular cycles, acne, hair changes, weight changes, symptom clusters, or
fertility patterns. Population statements ("PCOS can involve…") must never be
placed adjacent to the reader's own data in ways that complete the inference
for them.

### 12.3 Allowed personalization pattern (exact template)

> "Some of the patterns you recorded can occur in people with PCOS and other
> conditions. If this pattern persists, consider discussing it with a
> clinician."

Variants must preserve all three properties: (a) pattern-describing, (b)
multi-condition ("and other conditions" or equivalent — never a single
named condition as the implied answer), (c) clinician-directed. 6B tests
enforce the template properties, not just exact strings.

---

## 13. Endometriosis

### 13.1 Coverage

- What endometriosis is (tissue similar to uterine lining outside the uterus — pinned sources only).
- Pelvic pain and menstruation-related pain, in general terms.
- Impact on quality of life (work, daily life, wellbeing — plain language).
- Possible fertility implications (general; infertility-evaluation referral per §32 gap until pinned).
- Diagnostic limitations (why diagnosis is clinical and often delayed — descriptive of the care landscape, not a promise about any reader).
- **Why pain tracking alone cannot diagnose it** — required section: pain is real and worth recording and discussing, and simultaneously not diagnostic.

### 13.2 Language rules

- Avoid deterministic statements ("X means endometriosis", "severe cramps indicate…", severity-to-diagnosis mappings of any kind).
- Pain severity scales in content describe *communication* ("how to describe pain to a clinician"), never *classification*.
- The §21 pipeline example is the binding pattern: pain education + "when persistent pain is worth discussing" is allowed; naming endometriosis as the reader's explanation is prohibited.
- `individual_inference_allowed` is false for all endometriosis claims until and unless a `CURRENT_GUIDANCE` + reviewed inference rule exists (none defined in 6A).

---

## 14. Thyroid / other conditions

### 14.1 Educational differential categories (allowed)

Articles may teach — at literacy level, as **categories a clinician
considers**, each a pinned-source claim — conditions that can affect
menstrual/reproductive health, including:

- thyroid disorders
- hyperprolactinemia
- PCOS (§12)
- hypothalamic causes (e.g. energy-availability/stress-related disruption — careful, non-blaming language)
- primary ovarian insufficiency
- medications (as a category; no specific prescribing advice, no dosage content)
- structural causes (fibroids, polyps — descriptive only)
- pregnancy-related causes (with §15 restraint)

### 14.2 The hard boundary (normative)

**Do NOT create a symptom-to-diagnosis engine.** This prohibits, in content,
personalization, ranking, search, visuals, and metadata:

- decision trees, quizzes, or checklists that resolve to a condition;
- "if you logged X and Y, read this condition article *as your explanation*"
  linkages (condition articles may be linked from *general* contexts only);
- ranking condition articles by match to a user's symptoms;
- any `individual_inference_allowed: true` on differential-category claims in 6A (all false).

 Differentials are taught so users can have better clinician conversations
("these are some of the things clinicians consider —_test results, history,
and examination distinguish them"), never so users can self-triage to an answer.

---

## 15. Pregnancy content separation

Pregnancy content is partitioned into five sub-areas with a hard state/content split:

- **A. Pregnancy education** — how conception/pregnancy works at literacy level; testing basics (hCG timing, false negatives, confirm positives with a clinician — `EV-PREG-002` direction).
- **B. Pregnancy-related body changes** — physical/practical experience content (§6.7).
- **C. Pregnancy dating** — the dating hierarchy and what each basis means (§16); reading (never computing) EDDs and gestational age.
- **D. Pregnancy warning / red-flag information** — concerning symptoms and prompt-care guidance, sourced to current guidance (§27; source gaps flagged in §32 until pinned).
- **E. Postpartum content** — recovery basics and when to seek care (largely source-gap at spec time — §32; ships only as gaps close).

### 15.1 State rules (normative)

- **Phase 6A does NOT activate pregnancy mode.** No content interaction (reading, searching, bookmarking pregnancy articles) may enter, exit, or modify pregnancy mode.
- The existing legacy `health_contexts.pregnancy_context` selection **must NOT be reinterpreted** as pregnancy-mode architecture. It remains free user context with zero behavioral effect (per the backend contract doc §3.2 item 5).
- Explicit pregnancy mode remains governed by its own implemented contracts (backend `PUT/PATCH/DELETE /api/v1/reproductive/pregnancy`, mobile `PregnancyModeScreen`); content surfaces link to the mode screen where appropriate but never flip state.
- Discrepancy note (§35): the phase brief's "Phase 3 concern" language predates implementation — Phases 3–5 exist in the working tree. The binding rule for 6A/6B is narrower: **no new pregnancy behavior, no mode transitions from content, no dating computation in content.**

---

## 16. Pregnancy dating

### 16.1 Evidence hierarchy (normative, matches implementation)

1. **Clinically established dating** — clinician-provided EDD/gestational age; highest authority; stored verbatim with source; never silently overridden (implemented: `dating_source = clinician` → `CLINICALLY_CONFIRMED`; mobile preserves and labels it).
2. **First-trimester ultrasound dating when applicable** — second authority (`dating_source = ultrasound` → `ESTIMATED` in the implemented tier mapping).
3. **LMP-based dating when appropriate** — fallback estimate only, with confidence treatment; assumes regular cycles and certain recall, degrades otherwise (`EV-DATE-002` direction).

### 16.2 Limitations (required content wherever dating is taught)

- Ultrasound precision depends on measurement timing and quality (degrades later in gestation).
- LMP dating assumes regular cycles with typical mid-cycle ovulation; irregular cycles, recent hormonal contraception, and uncertain recall reduce accuracy.
- An EDD is an estimate, not an appointment: "When Pregnancy Goes Past Your Due Date" concepts (post-term evaluation exists as clinical care) may be taught only from the pinned ACOG source, without thresholds invented in content.

### 16.3 Prohibitions (normative)

- **Do not calculate or change an EDD in Phase 6A** (no document math, no worked examples that compute a reader's due date), and 6B must not either (§33).
- **Do not treat a MenoMate cycle prediction as pregnancy dating.** Next-period predictions and gestational age are different quantities from different methods; content must never convert one into the other, even illustratively with the reader's own dates.

---

## 17. Reproductive aging

### 17.1 Coverage

- Reproductive aging as a multi-year process (not an event).
- Perimenopause: transition characteristics — rising cycle variability, persistent length/bleeding-pattern changes (pattern language per the safety boundaries §5, `EV-PERI-001` direction, STRAW+-style staging *described*, never applied).
- Menopause: what the term means (12 months without menstruation as the clinical convention — pinned source required before drafting; gap-flagged in §32 until then).
- Cycle variability during transition and its effect on estimate confidence (implemented direction: more variability → `LOW_CONFIDENCE`/`INSUFFICIENT_DATA`, never more diagnostic).
- Symptom changes (vasomotor symptoms, sleep disturbance, mood changes — commonly reported and nonspecific, `EV-PERI-002` direction; never diagnostic criteria).
- Fertility decline with age (general, from "How Aging Affects Fertility and Pregnancy" once pinned; no individual probabilities).
- Limitations of hormone testing ("Do I Need Hormone Testing During Perimenopause?" once pinned — tests do not date the transition or predict individual fertility).
- When clinical evaluation may be appropriate (persistent abnormal bleeding, severe symptoms — red-flag blocks).

### 17.2 Boundaries (normative)

- **Avoid giving an individual fertility probability** unless supported by a validated model **and** explicitly reviewed — no such model exists in 6A; the default is general language only.
- **Do not turn age alone into a prediction of an individual's fertility.** Age bands may prioritize general education (§20); they may never generate personal fertility statements, timelines, or countdowns.
- Stage labels ("you are perimenopausal", "in menopause", "postmenopausal" applied to the reader) are banned in all content surfaces, per the safety boundaries §4.

---

## 18. Contraception (dedicated safety class)

Contraception content carries the strictest sourcing rule in this specification because stale numbers cause real harm.

### 18.1 Allowed educational scope

MenoMate may provide educational information about:

- barrier methods; hormonal contraception; long-acting reversible contraception; emergency contraception; fertility-awareness methods (with §10 limitations taught alongside, never separated).

### 18.2 Sourcing rules (normative)

- Actionable effectiveness, eligibility, contraindications, and current recommendations **must come from current authoritative sources** (the §2.3 program list plus current CDC contraceptive guidance where applicable — pinned at drafting).
- **Do not reuse old effectiveness numbers from historical supplied papers as if they are current.** Any effectiveness figure requires `CURRENT_GUIDANCE` status + current edition + clinical review; otherwise the article teaches method *concepts* without numbers.
- Emergency-contraception content is timing-sensitive: time windows and eligibility only from current guidance; until pinned, the article is a source gap (§32), not a hedged draft.

### 18.3 The central prohibition (normative)

**MenoMate fertility predictions are NOT contraceptive protection.** Every contraception-adjacent article states this; fertility-awareness content states that app estimates are not a certified method and that the app is not a contraceptive device. Banned language (§10.2) is enforced in 6B tests across articles, visuals, examples, and metadata.

---

## 19. Symptoms / wellbeing

Insights may discuss: pain, mood, sleep, appetite, energy, bloating, headaches, breast symptoms, skin changes, general wellbeing.

### 19.1 Population-language rule (normative)

Population-level research must not be turned into deterministic statements about an individual.

- Avoid: "Because you are on cycle day X, you will feel Y."
- Prefer: "Some people notice Y around this stage of the cycle, although experiences vary."

This extends the shipped Insight library rule (no inappropriate certainty — "will"/"always"/guarantees banned by `test/insight_library_test.dart`) to long-form content. Phase/day associations are taught as *common patterns with wide variation*, with the variation stated in the same paragraph, not footnoted away.

### 19.2 Scope notes

- Self-care options follow the existing library's conservative framing (options among others, no "X reduces Y" treatment claims, no prescriptions/dosages/supplement recommendations, nutrition as nutrient sources only).
- Symptom content links to when-to-seek-care blocks where severity is discussed; severity language describes communication with clinicians, never self-classification into conditions.

---

## 20. Personalization

### 20.1 The principle (normative)

**Personalization changes PRIORITY, not ACCESS.** All users can access the full educational library (browse, search, read everything). Recorded user data may influence which content is surfaced first ("For you" ordering, contextual introductions). It may never gate availability, and it may never generate conclusions.

### 20.2 Allowed signals (priority inputs only)

- recent period start (recency)
- cycle variability band (coarse, server-computed; never raw scores or thresholds in content logic)
- recorded symptoms (logged-day counts only, as the existing symptom aggregate)
- fertility observations (type presence only — e.g. LH rows exist → prioritize the LH article; values never interpreted)
- TTC context **only if explicitly recorded** (never inferred from behavior, age, or estimates)
- age band (coarse, from birth month/year precision)
- reproductive-aging context (explicitly recorded notes → expectation-setting content, never stage inference)
- pregnancy status **only when explicitly established** through the pregnancy-mode architecture (never lateness/symptoms/estimates)
- health conditions explicitly supplied by the user / clinical context (surface matching *literacy* content the recording implies interest in — never suspicion)
- medications explicitly recorded (same literacy-surfacing rule)
- the user's recent Insight history (diversity + freshness, §22)

### 20.3 Prohibitions (normative)

- **Never infer a sensitive condition from symptoms alone** — no signal or combination of signals (symptoms, variability, age, observations, estimates) may produce, prioritize-as-answer, or imply a condition. The §21 example is binding.
- No personalization output may carry diagnostic, prognostic, or eligibility conclusions.
- TTC and pregnancy signals require explicit user establishment; everything else in §20.2 degrades gracefully to safe defaults for thin-data users.

---

## 21. Personalization pipeline

Normative data flow (each stage constrained):

```text
User data (OBSERVED / ESTIMATED, verbatim)
  → context matcher (coarse bands + explicit flags only; no scores, §22)
  → relevant topics (§6 categories, never conditions)
  → evidence-backed article (claims resolved via §7, all CLINICALLY_REVIEWED for publication)
  → contextual introduction (pattern language only; §21.1 template properties)
  → educational content (§23 schema)
  → safety guidance (disclaimer + red-flags + clinician direction, §26–§27)
```

### 21.1 Binding example

Observed: "user logged severe period pain repeatedly."

Allowed:

> "Period pain can have several causes. Here's how menstrual pain works and
> when persistent pain is worth discussing with a clinician."

Not allowed:

> "Your logs suggest you have endometriosis."

The allowed form has three checkable properties 6B tests enforce: (1) no
condition named as the reader's explanation (condition *literacy* links, if
any, are presented as general education with multi-condition framing); (2) no
certainty or inference verbs about the reader ("suggest", "indicate",
"likely", "consistent with *your*…"); (3) clinician direction present.

### 21.2 Contextual-introduction rules

- Introductions reference *recorded patterns* ("you've logged…", "your recent
  cycles show more variation…"), never interpretations ("because you have…").
- Introductions for suppressed/unknown states stay neutral (e.g. pregnancy
  suppression copy implies no medical conclusion, per the safety boundaries).
- Introductions are themselves content: sourced where they contain health
  claims, reviewed, and banned-phrase tested.

---

## 22. Article ranking

Transparent, score-free prioritization (conceptual model for 6B):

- Priority **may** consider: explicit user context, recent observations,
  article relevance to the matched topic, safety relevance (red-flag
  literacy rises when relevant symptoms are logged — as education, never
  triage), freshness (new/updated articles), diversity (no topic flooding),
  previously viewed content (deprioritize repeats).
- Ranking inputs are coarse bands and flags; weights, if any, are fixed,
  documented in the article's `personalization_rules`, and contain no
  medical parameters.
- **Do NOT create a medical risk score. Do NOT rank users by disease
  probability. Do NOT produce a "health score."** No number, band, color, or
  ordering may function as a health assessment of the reader. "For you"
  ordering is presented as relevance ("Suggested because you logged…"),
  with the reason visible, never as a verdict.

---

## 23. Article structure

### 23.1 Insight article schema (normative field set for 6B models)

```text
Insight
├── id                    # stable, e.g. INS-…
├── slug                  # unique URL key
├── title
├── subtitle
├── category              # one §6 slug
├── hero                  # hero concept (§24 metadata)
├── estimated_read_time   # minutes, honestly computed from body length
├── content_blocks[]      # §23.2, ordered
├── evidence[]            # claim_ids (§7) backing this article
├── provenance            # EVIDENCE_SUPPORTED (+ OBSERVED only for the
│                         #   contextual intro's recorded-pattern references)
├── personalization[]     # personalization_rules (§31): signals + reasons
├── safety                # disclaimers + red_flags + clinician_guidance (§26)
└── visual_assets[]       # §24 metadata
```

### 23.2 Content blocks (allowed set; compose per article — not every article identical)

- `hero` — title concept + hero visual + one-line standfirst (no medical claims in the standfirst beyond the title's scope).
- `introduction` — plain-language framing + uncertainty posture + what the article will/won't do.
- `section` — headed body sections (`paragraph` bodies).
- `paragraph` — body text; each non-trivial health sentence resolves to an `evidence[]` claim.
- `callout` — caution/expectation-setting ("Estimates are estimates…", "Experiences vary…").
- `key-fact` — single sourced takeaway with visible attribution (§25).
- `timeline` — stage/phase informational sequences (cycle, transition, pregnancy stages — ranges and variation stated, no guarantees).
- `comparison` — marker/method/option tables with limitations columns (limitations column mandatory).
- `illustration` — informational visual with caption + scientific context (§24).
- `checklist` — tracking checklists and "what to bring to an appointment" lists (never self-diagnosis checklists, §14).
- `myth-vs-fact` — stated myth, sourced correction, uncertainty preserved.
- `when-to-seek-care` — red-flag block (§27) + clinician-direction + preparation checklist.
- `sources` — rendered source list from §25 metadata (every article, no exceptions).

---

## 24. Visual content

### 24.1 Supported visual concepts

Hero images, vertical banners, diagrams, cycle illustrations, anatomy
illustrations, hormone timelines, fertility-window diagrams, symptom
illustrations, pregnancy-development visuals, reproductive-aging timelines.

### 24.2 Information-first rule (normative)

Visuals must communicate information rather than function only as
decoration: every visual carries a caption and scientific context stating
what it shows *and its limits* (e.g. a window diagram is labeled an
illustrative population schematic, never a personal calendar; hormone
timelines show typical patterns with variation bands, not exact curves).

### 24.3 Visual metadata (normative field set for 6B models)

- `asset_id` — stable ID (`VIS-…`).
- `type` — hero / banner / diagram / illustration / timeline / chart.
- `alt_text` — full textual equivalent (accessibility; reviewed like body copy).
- `caption` — visible caption including limits ("Illustrative pattern — individual timing varies.").
- `scientific_context` — what the visual is based on + what it must not be read as.
- `source` — source ID(s) from §29 for data-driven visuals.
- `copyright/licensing status` — origin + license; no unlicensed clinical imagery; generated illustrations reviewed for medical misinformation before approval.

### 24.4 Misinformation guard

Avoid medical misinformation in generated illustrations: anatomy must be
accurate at patient-education level; no invented structures, mechanisms, or
efficacy imagery; no visual that implies diagnosis, guarantees, or
contraceptive protection. Visuals go through §28 review with the same
checklist as text.

---

## 25. Source display

Each article exposes its sources (rendered `sources` block, §23.2) with, per source:

- source title; organization/journal; publication year (or edition);
  evidence type; link where available (URL/DOI).

### 25.1 Type distinction (visible to users, plain words)

- research paper ("Individual research study — one piece of evidence, not guidance on its own");
- systematic review ("Review combining multiple studies");
- guideline ("Clinical guidance from a professional body");
- professional society guidance ("Patient-education material from…");
- educational source (reference databases such as USDA-FDC — facts only, never advice).

### 25.2 Rules

- Do not present a manufacturer claim as independent evidence (test-kit makers, app vendors, supplement sellers are never cited as evidence for efficacy).
- Historical sources display with their date and a "historical context" marker; they never appear without the current-guidance counterpart they contextualize.
- The *display* layer never upgrades evidence: a research paper is labeled a research paper even when its claim is well-established elsewhere.

---

## 26. Safety model

### 26.1 Per-article safety evaluation (normative checklist — every health article)

1. **diagnostic implication** — could any sentence, intro, visual, or link arrangement imply the reader has a condition? (§§12–14, §21.1)
2. **treatment advice** — prescriptions, dosages, supplement/medication recommendations, hormone-mechanism treatment claims? (Prohibited outright.)
3. **emergency advice** — red-flag completeness for the topic; no invented thresholds (§27).
4. **pregnancy safety** — could content be misread as pregnancy guidance/diagnosis/dating? (§§15–16)
5. **fertility/contraception confusion** — could estimates be read as contraception or guarantees? (§§10, 18)
6. **overconfidence** — certainty verbs, exact numbers without sources, variation omitted?
7. **false reassurance** — "usually nothing to worry about" without the when-to-seek-care counterpart?
8. **unnecessary alarm** — worst-case framing without base-rate honesty?

### 26.2 Required safety components (every article)

- **disclaimers** — educational-purpose statement + "not medical advice, not a diagnosis, talk to your clinician" + estimate-specific disclaimer on fertility-adjacent articles (extends the fixed estimate disclaimer in the safety boundaries). Disclaimers are specific and proximal (adjacent to the claim they bound), not a single distant footer.
- **red_flags** — topic-appropriate red-flag block (§27) wherever symptoms, pain, bleeding, pregnancy, or medications are discussed.
- **clinician_guidance** — when to discuss + what to bring (records, patterns, questions).

Disclaimers must stay useful: specific, short, adjacent — never so broad or so repeated that readers learn to skip them. One precise disclaimer beats three generic ones.

---

## 27. Red flags

### 27.1 Reusable mechanism (for 6B)

Red-flag content is a shared, reviewed block library (`RFB-…` IDs), not per-article prose: articles reference blocks; blocks are versioned with their sources; updating a block updates every article using it (with re-review of affected articles). Blocks contain: concern description (plain language), why promptness matters (one line, sourced), what to do (contact clinician/urgent care — escalation wording from current guidance, never "wait and see" for red flags, never panic language).

### 27.2 Situations covered (from the program's red-flag inventory)

Situations that may warrant prompt medical evaluation can include: severe or unusual bleeding; severe pelvic/abdominal pain; fainting or significant weakness; pregnancy-associated concerning symptoms; sudden severe symptoms; symptoms suggesting urgent medical problems. (These parallel the existing "When to seek care" Learn content: very heavy bleeding, severe daily-life-stopping pain, fainting, bleeding between periods.)

### 27.3 Threshold honesty (normative)

**Do not invent precise emergency thresholds** (milliliters, pads-per-hour counts, pain scores, vital-sign cutoffs) **if the source registry does not support them.** Where specific thresholds are required, source them from current clinical guidance (`CURRENT_GUIDANCE` + pinned edition); until then the block uses qualitative prompt-care language and is marked as a source gap for threshold precision (§32). A qualitative-but-honest block ships; a precise-but-unsourced block never does.

---

## 28. Clinical review workflow

Normative pipeline (states map to §31 statuses):

```text
Research extraction (corpus item → candidate claims, §7 schema, default NOT_CLINICALLY_REVIEWED)
  → evidence classification (§3 status + limitations + population, curator)
  → article drafting (schema §23, pattern language §§12–14/17/19, visuals §24)
  → safety review (§26 checklist + banned-phrase scan + §21.1 intro properties)
  → clinical review (checklist §28.1; per claim-in-article)
  → publication (§31 PUBLISHED; all non-trivial claims CLINICALLY_REVIEWED)
  → periodic source review (currentness sweep per §29; guideline updates re-open affected articles)
```

### 28.1 Clinical review verifies

- medical accuracy (claims match sources; no scope creep);
- safety (§26 checklist sign-off);
- wording (diagnostic boundaries, certainty verbs, variation stated);
- diagnostic boundaries (no prohibited inference paths, §§12–14);
- actionable advice (only `CURRENT_GUIDANCE`-backed actions; nothing stronger than sources);
- pregnancy implications (no inference, no dating math, mode untouched);
- contraception implications (boundaries §10.2/§18 intact);
- citations (every non-trivial claim resolves; links valid; editions current).

### 28.2 Separation of duties

Clinical review is distinct from engineering QA. Engineers verify schema,
rendering, tests, and that review gates are enforced in code (status
transitions blocked, banned-phrase tests); they do not approve medical
content. Reviewers approve content; they do not approve code. The gate
between `CLINICAL_REVIEW` and `PUBLISHED` requires both sign-offs recorded.

---

## 29. Source versioning

### 29.1 Source record schema (normative field set for 6B models)

- `source_id` — stable (`SRC-…`); never reused.
- `title` — full title.
- `authors/organization` — as published.
- `publication date` — edition or year ("living guideline — verify current edition" where applicable).
- `source type` — research-paper / systematic-review / guideline / society-guidance / educational-source / historical (§25.1 + `HISTORICAL_CONTEXT`).
- `URL/DOI` — where applicable; required for `CURRENT_GUIDANCE` sources.
- `topic` — §6 slug(s).
- `evidence status` — the status this source can confer (§3).
- `currentness` — `current` / `superseded` / `unknown` (default `unknown` until checked).
- `clinical review status` — §4 (source-level: has a clinician confirmed this source says what the registry claims it says — distinct from per-claim article review).

### 29.2 Supersession rule (normative)

If a current guideline supersedes an older source, retain the historical
source for provenance (`currentness = superseded`, usable only with
`HISTORICAL_CONTEXT` claims) but **do not silently use it as current
guidance**: affected claims are re-pointed to the current source and
re-reviewed; articles whose claims cannot be re-pointed revert to
`CLINICAL_REVIEW` until resolved. Periodic source review (§28) runs this
sweep on a defined cadence (cadence itself a Phase 6B operational decision,
minimum: check living-guideline editions before each content release).

---

## 30. Initial article catalog

The catalog below is **coverage, without ranking** ("without ranking articles
as 'best'"). Order here is categorical, not preferential; 6B ranking (§22)
computes priority at serve time and must not persist a "best" ordering.

MENSTRUAL CYCLE
- Understanding Your Menstrual Cycle
- Why Cycle Length Can Change
- What Happens During the Follicular Phase?
- What Happens During the Luteal Phase?
- Understanding Period Pain
- Understanding Irregular Periods

OVULATION & FERTILITY
- What Is Ovulation?
- How LH Tests Work
- What Basal Body Temperature Can Tell You
- Cervical Mucus and Fertility
- How Ovulation Estimates Work
- Understanding the Fertile Window
- Trying to Conceive: Timing and Cycle Awareness

REPRODUCTIVE HEALTH
- PCOS: Understanding the Condition
- Endometriosis and Pelvic Pain
- Thyroid Health and the Menstrual Cycle
- When Period Changes Are Worth Discussing

PREGNANCY
- How Pregnancy Dating Works
- What Changes During Early Pregnancy
- Understanding the Due Date
- Pregnancy Symptoms and When to Seek Care

REPRODUCTIVE AGING
- What Happens During Perimenopause?
- Understanding Menopause
- How Reproductive Aging Affects Cycles
- Fertility and Age

CONTRACEPTION
- Understanding Contraceptive Options
- Fertility Awareness and Its Limitations
- How Emergency Contraception Works

MIND / WELLBEING
- Sleep and the Menstrual Cycle
- Stress and Cycle Changes
- Menstrual Health Without Stigma

Do not interpret this list as a ranking. Each article is drafted only when
its claims resolve to pinned sources; otherwise it waits as a titled gap
(§32), not a hedged draft.

---

## 31. Article metadata

### 31.1 Field set (normative for 6B models; extends §23.1)

- `id`, `slug`, `title`, `subtitle`, `category` (§6 slug), `tags`
- `status` — workflow state (§31.2)
- `publication_status` — derived visibility (`draft-visible` to reviewers only / `published` / `archived-hidden`); never computed from `status` alone without the review gate record
- `evidence_status` — roll-up of the article's claims (weakest non-trivial claim governs; `HISTORICAL_CONTEXT`-only passages excluded from the roll-up but labeled)
- `clinical_review_status` — roll-up (all non-trivial claims `CLINICALLY_REVIEWED` required for publication)
- `estimated_read_time`, `created_at`, `updated_at`, `reviewed_at`
- `source_ids` — union of claim sources, deduplicated
- `content_blocks`, `safety` (§26.2 components), `personalization_rules` (signals + human-readable reasons, §22), `visual_assets` (§24.3)

### 31.2 Article statuses (normative state machine)

- `DRAFT` → `EVIDENCE_REVIEW` (claims extracted + classified) → `CLINICAL_REVIEW` (safety review passed) → `PUBLISHED` (clinical + engineering sign-off) → `ARCHIVED` (superseded/withdrawn; retained for provenance, never served).
- Backward transitions allowed with reason recorded (e.g. source supersession re-opens to `CLINICAL_REVIEW`).
- `PUBLISHED` requires: every non-trivial claim `CLINICALLY_REVIEWED`; safety components present; banned-phrase scan clean; visuals reviewed; `personalization_rules` documented with reasons.

---

## 32. Future source gaps

Topics where current guidance must be refreshed or expanded **before
actionable production content** (titles may exist in §30 as placeholders;
actionable drafting waits):

- contraception effectiveness and current recommendations (numbers need `CURRENT_GUIDANCE`; concepts may precede numbers)
- emergency contraception (timing/eligibility windows)
- pregnancy warning signs (threshold precision, §27.3)
- postpartum care (recovery guidance, care-seeking thresholds)
- miscarriage / ectopic-pregnancy safety content (sensitive; current-guidance-only; red-flag blocks first, explainers after)
- PCOS clinical guidance (diagnostic-criteria literacy + referral framing)
- endometriosis clinical guidance (diagnosis landscape + referral framing)
- thyroid / reproductive-health guidance (cause-category literacy)
- perimenopause / menopause guidance (menopause definition source; hormone-testing limits from the named ACOG source)
- infertility evaluation (referral timing/definition from named ACOG/ASRM sources)
- fertility preservation (options literacy; rapidly evolving — edition-sensitive)
- adolescent menstrual health, **if** the product will support younger users (age-appropriate language, safeguarding considerations — product decision required first; no content until then)

**Do not invent missing evidence.** A gap is recorded with the topic, what is
missing, what it blocks, and the intended source; the catalog title waits.

---

## 33. Phase 6B implementation contract

> This section is the consolidated 6B contract. §33.1/§33.2 remain the
> binding allow/forbid lists (extended here for the editorial experience,
> §§36–46). §33.3 groups the same work into delivery tracks so 6B scope is
> unambiguous. Nothing here licenses what §33.2 forbids.

### 33.1 Phase 6B MAY implement

- article/content models (per §§23, 24.3, 29.1, 31.1, extended by §§36, 42, 46)
- local Insight content library (bundled, offline-first, following the `lib/content/` deterministic-library pattern; strongly typed local registry first, §47)
- article rendering (long-form schema, hero/banner concepts; flexible article renderer per §39 — supports varying block combinations, never forces every block)
- presentation models: Insight Card, Editorial Cover, Hero Artwork, Inline Visual, Editorial Feature / Magazine Story renderer (§§36, 42–43, 45) — presentation config only, no second article engine
- Home discovery surface (§37): Today's Insight card, supporting Insight Cards, occasional Editorial Feature slot, See All entry point
- Insights library destination (§38): For You, Featured, Explore (the §6 taxonomy as category pages), Latest / More to Explore
- category browsing (the §6 taxonomy)
- search/filtering (over titles, tags, categories — never symptom-to-condition matching, §14)
- contextual prioritization (priority-only personalization §§20–22 with visible reasons; contextual relevance + priority adjustment only, §37–§38)
- evidence/source display (§25)
- visual asset support (§24 as expanded by §42, with misinformation review; decorative-vs-informational marking, accessibility text, licensing/attribution)
- safety blocks (disclaimers, red flags, clinician guidance — §§26–27, shared block library; required in every article flow position per §39)
- accessibility implementation (§§40–42: alt text, semantic text, readable typography, no image-only medical information)
- tests (banned-phrase enforcement extending the existing Insight-library test pattern; provenance non-upgrade tests; personalization priority-vs-access tests; no-risk-score / no-diagnosis tests; review-gate tests; presentation tests: one article body renders across Card/Cover/Hero/Inline without content duplication; accessibility tests: every informational visual has alt text + non-image meaning carrier)

### 33.2 Phase 6B MUST NOT

- modify cycle prediction algorithms (`cycle_calculator.py`, `robust_wma_v1`)
- modify fertility estimator mathematics (`fertility_estimator.py`, `fertility_v1` gating/thresholds)
- create diagnostic algorithms (no classifiers, scorers, quizzes resolving to conditions)
- infer medical diagnoses (from any signal combination, §20.3)
- reinterpret legacy `pregnancy_context` (stays zero-behavioral-effect context)
- activate pregnancy mode (no content-driven mode transitions, §15.1)
- turn fertility estimates into contraception (boundaries §§10.2, 18.3, in content and tests)
- introduce unsupported medical thresholds (numbers only from `CURRENT_GUIDANCE` + review)
- silently replace evidence with model-generated claims (no LLM/AI-authored medical claims without full §28 passage; the existing select-then-enhance posture — deterministic library authoritative, AI optional surround — is preserved)
- deploy production
- build CMS infrastructure, server-side content management, recommendation ML, analytics platform, medical decision support, or an AI-generated medical content pipeline (§47 — all deferred, not 6B)

### 33.3 Contract tracks (normative grouping of §33.1)

CONTENT (§§6–7, 23, 25, 29, 31–32, 36, 46)
- typed Insight model + article registry (one body per article, §46; statuses §31.2)
- source registry + evidence metadata (claims resolve per §7; display per §25; versioning per §29)
- safety metadata (per-article safety components §26.2; red-flag block references §27)

PRESENTATION (§§23–24, 36, 39–43, 45–46)
- Insight Card, Editorial Feature, Editorial Cover, Hero Artwork, Inline Visual
- flexible article renderer (§39: supports varying block combinations; Magazine Story = Insight Article + richer presentation config, §45, no separate engine)
- visual storytelling support (§40) with accessibility guarantees (§41)

DISCOVERY (§§20–22, 37–38, 43)
- Home recommendations (Today's Insight + supporting cards + occasional Editorial Feature + See All, §37)
- For You / Featured / Explore categories / Latest / More to Explore (§38)
- library + category pages + featured sections served from the same article bodies (§43, §46)

PERSONALIZATION (§§20–22, 37–38)
- contextual relevance + priority adjustment only
- no diagnosis, no medical risk score, no health score, no disease-probability ranking (§22, §37)

ACCESSIBILITY (§§24, 40–42)
- alt text on every informational visual; semantic text alongside visual typography
- readable mobile typography; important information never exists only inside images (§41)

---

## 34. Acceptance criteria

The document is complete only if (self-check against this specification):

1. All ten major topic categories are represented (§6.1–§6.10). ✓
2. Evidence status and clinical review status are separate (§§3–4). ✓
3. Provenance layers are explicit (§5, four layers + rules). ✓
4. User observation is clearly separated from diagnosis (§§5.2, 21). ✓
5. Estimated fertility information is clearly separated from clinical confirmation (§§5, 9, 10, 11). ✓
6. TTC education is supported (§10.1, catalog entries). ✓
7. Fertility awareness is supported with explicit contraception boundaries (§§10.2, 18). ✓
8. PCOS/endometriosis/thyroid content cannot become diagnostic by implication (§§12–14, §21.1, §22 prohibitions). ✓
9. Pregnancy education is supported without activating pregnancy mode (§§6.6–6.7, 15–16). ✓
10. Reproductive aging is supported (§§6.8, 17). ✓
11. Contraception is treated as a safety-sensitive topic (§§6.9, 18). ✓
12. Long-form article content is supported (§23 + §30 catalog). ✓
13. Visual assets are part of the content model (§24). ✓
14. Sources and citations are first-class metadata (§§25, 29). ✓
15. Clinical review workflow is defined (§28, distinct from engineering QA). ✓
16. Personalization affects priority, not content availability (§§20–22). ✓
17. No health-risk score or disease-probability score is introduced (§22 prohibitions + 6B tests). ✓
18. Existing prediction systems remain frozen (§11.2, §33.2). ✓
19. Phase 6B implementation boundaries are explicit (§33 allow/forbid). ✓
20. Future source gaps are documented (§32 + gap-marked claims in §7.2). ✓
21. Editorial presentation model is formally defined (§36: one-body-many-forms + seven terms). ✓ (§48.8)
22. Home (discovery sample) and Insights (full library) responsibilities are separated (§§37–38). ✓ (§48.9)
23. Article flow is defined with flexible composition (§39: recommended order, renderer supports varying structures). ✓
24. Visual storytelling is required with text-alongside-visual guarantees (§40). ✓
25. Text-inside-visuals is supported with accessibility guards (semantic text separate, no image-only medical information, §41). ✓ (§48.11)
26. Visual asset model carries roles, accessibility, and licensing metadata without requiring all types per article (§42). ✓
27. Responsive presentation reuses one body across surfaces without duplication (§§43, 46). ✓ (§48.10)
28. Editorial design principles are documented with own-identity / no-copy rule (§44). ✓
29. Magazine stories are supported as presentation config, not a second engine (§45). ✓ (§48.12)
30. Content vs presentation are separated with a reuse rule (§46). ✓ (§48.10)
31. Phase 6B contract covers content / presentation / discovery / personalization / accessibility tracks (§33.3). ✓ (§48.13)
32. Non-goals are explicit; 6B starts from a typed local registry with remote-delivery room (§47). ✓ (§48.14)

---

## 35. Engineering rule, discrepancies, and verification

### 35.1 Terminology conformance

Terminology matches the inspected implementation: estimate states
(`AVAILABLE`/`LOW_CONFIDENCE`/`INSUFFICIENT_DATA`/`SUPPRESSED`) and
`evidence_source` values per `fertility_estimator.py` /
`lib/models/reproductive.dart`; dating tiers per `pregnancy_dating.py`;
observation enums per `ObservationTypeEnum` (backend) — distinct from the
daily-log discharge volume scale; estimator identities `robust_wma_v1` and
`fertility_v1` 1.0.0; `DataState` (Fresh/Cached/PendingSync/ConflictState/
Unavailable/NoData) offline semantics; `InsightPiece`/`InsightPair`/
`InsightContext` content primitives and their test-enforced content rules;
Care advisory-only boundary with disclaimer footer and tiered triage.

### 35.2 Discrepancies documented (code authoritative, nothing edited)

1. **Phase numbering vs implementation.** The phase brief's §§15–16 speak as
   if pregnancy mode is a future "Phase 3 concern" and dating computation a
   future decision. The working tree already implements Phases 2–5
   (`app/services/fertility_estimator.py`, `pregnancy.py`,
   `pregnancy_dating.py`, `reproductive_aging.py`;
   `app/api/v1/reproductive.py`; mobile `PregnancyModeScreen`,
   `AgingContextScreen`, `ReproductiveRepository`, Drift v5). This
   specification therefore binds 6A/6B to the narrower rule — *no new
   pregnancy behavior, no mode transitions from content, no dating math in
   content* — rather than the brief's broader "does not exist yet" framing.
2. **No corpus files in-repo** (§2.1): the brief's "already supplied"
   research corpus is not present as files in either working tree; handled
   via source-gap marking, not assumption.
3. **Phase 0 evidence entries are NEEDS-REVIEW placeholders** (all `EV-…`
   entries); §7.2 entries inheriting them are scaffolding until verified —
   stated in each entry, not silently promoted.
4. No other conflicts found; no existing document required modification.

### 35.3 Phase 6A verification

- [x] Branch verified (`frontend-development`) before writing.
- [x] Existing documentation and code inspected read-only (see header list); terminology conforms (§35.1); discrepancies recorded, not edited (§35.2).
- [x] Created `docs/insights-evidence-content-spec.md` (this file) — the only change in this phase.
- [x] No Flutter UI, backend API, prediction-logic, schema/migration, auth, deployment, commit, or push action taken.
- [ ] Phase 6B NOT started. STOP.

---

## 36. Insight presentation model (editorial experience)

### 36.1 Editorial direction (normative framing)

MenoMate Insights is an **editorial health-magazine experience**, not a
conventional article list. The product direction is an approachable,
Flo-inspired *category* of health education — calm, visual, magazine-like
explanations of reproductive health.

- Flo (or any comparable app) is a **high-level product-category reference
  only** for the concept of approachable health education.
- Do NOT copy any company's proprietary UI, artwork, branding, illustrations,
  trade dress, or content. MenoMate keeps its own visual identity (§44).
- Visual richness never weakens the evidence, safety, or provenance
  architecture (§§3–5, 26–28): every visual and presentation surface is
  inside the review gate, not beside it.

### 36.2 One article, many presentations (normative)

An Insight has **one underlying article body** (§§23, 46) and **multiple
presentation forms** that surface it without duplicating content:

```text
Insight Article
    ├── Editorial Cover
    ├── Feed Card
    ├── Hero Artwork
    ├── Inline Visuals
    ├── Article Content
    └── Safety/Evidence
```

Rules:

1. Presentation forms reference the article; they never fork its body (§46).
2. Every presentation form that carries a health claim resolves to the same
   claim-registry entries (§7) and passes the same §28 review.
3. Safety and evidence travel with every presentation: no cover, card,
   feature, or visual may imply what the article body does not say, omit the
   article's hedging, or drop its disclaimers where disclaimers are required
   (§§26, 39).

### 36.3 Terminology (normative definitions)

- **INSIGHT CARD** — A compact representation of an Insight shown in
  feeds/lists (Home, category rows, search results, related lists). Title +
  short supporting line + cover/thumbnail visual + category + read time.
  Tappable into the full article. Never carries the article's full teaching;
  never functions as a diagnosis or verdict (§§21–22).
- **EDITORIAL COVER** — A designed visual representation of an Insight:
  composed illustration/graphic with integrated typography (title, subtitle,
  category, small supporting phrase — §41). Used for feed cards, library
  grids, and feature slots. The text in the composition is presentational;
  the article meaning must survive without it (§41).
- **HERO ARTWORK** — The prominent visual at the beginning of an opened
  Insight article (top of the article flow, §39). Sets the topic visually;
  carries caption + alt text + scientific context per §42. Never a personal
  calendar, never a diagnostic image (§24.2).
- **INLINE VISUAL** — A visual explanation embedded within article content
  (diagram, timeline, comparison graphic, myth-vs-fact visual, simplified
  anatomy — §40). Always accompanied by surrounding explanatory text; readers
  must not need to interpret a medical graphic unaided (§40.3).
- **EDITORIAL FEATURE** — A larger magazine-style presentation of an Insight
  intended to be visually prominent (Home feature slot, Featured shelf in the
  library). Full-bleed or large cover, large typography, sequential visuals
  (§45). A presentation configuration, not a separate content type.
- **INSIGHT ARTICLE** — The complete educational reading experience: content
  blocks (§23.2 as ordered by §39) + evidence/sources (§25) + safety (§26).
  The single source of truth for what the Insight teaches.
- **INSIGHTS LIBRARY** — The complete collection/discovery experience (the
  dedicated Insights destination, §38): For You, Featured, Explore
  categories, Latest / More to Explore. Browsable and searchable in full by
  every user (§20.1).

### 36.4 Relation to implemented V1 (code authoritative)

The working tree at spec time ships a short-form Daily Insight system
(`InsightPiece`/`InsightPair`/`InsightInput`, `DailyInsightNotifier`,
`DailyInsightCard`, InsightsTab V1 sections "For you today / Understand your
cycle / Cycle trends / Symptom patterns / Learn"). That V1 remains
authoritative for what is implemented. The §§36–46 presentation model is the
**6B editorial target**: long-form Insight Articles reuse the same
evidence-bounded, deterministic-library posture (bundled, offline-first,
select-then-enhance compatible) at magazine depth. Where phase language here
differs from shipped code, current code governs (§35).

---

## 37. Home experience (discovery surface, not the library)

### 37.1 Home is a discovery surface (normative)

Home surfaces a small, fresh, contextually relevant sample of Insights. It is
**not** the complete library: the full collection lives in the Insights
destination (§38). Home's job is invite → orient → hand off ("See All
Insights").

### 37.2 Home slots

A. **Today's Insight**
   - One contextually relevant, evidence-backed article in concise card
     presentation (Insight Card, §36.3).
   - Selected by the priority-only personalization rules (§§20–22): recorded
     context may raise relevance ("Suggested because you logged…"), never
     restrict availability, never conclude.
   - Concise: title + one supporting line + read time. The teaching stays in
     the article, not the card.

B. **Supporting Insight Cards**
   - A small set of smaller recommendations (typically 2–4) with **diverse
     topics** (diversity rule, §22): do not flood one topic, and avoid
     repeatedly showing the same subject across days (freshness +
     viewed-history deprioritization, §22).
   - Safe defaults for thin-data users (§20.3); general-interest and
     tracking-literacy content is preferred over sensitive topics when
     context is sparse.

C. **Editorial Feature**
   - A larger magazine-style visual (Editorial Feature, §36.3/§45) that may
     **occasionally** appear as a prominent story — visually richer than a
     normal card (full-width cover, large typography).
   - Occasional by design: at most one feature slot, not a feed of features;
     rotation governed by freshness/diversity, never by medical urgency.
   - Still an Insight Article underneath (§45): tapping opens the standard
     article flow (§39), not a separate story engine.

D. **See All Insights**
   - A persistent entry point navigating to the dedicated Insights library
     (§38). Always visible from Home regardless of personalization state.

### 37.3 Home rules (normative)

1. Personalization affects **what is surfaced first** (ordering + which
   eligible articles fill slots), never what exists: the whole library
   remains browsable in §38 (§20.1).
2. **Do not create a medical recommendation or risk score** on Home: no
   "health score", no disease-probability ranking, no urgency badge, no
   severity color, no ordering that reads as a verdict about the reader
   (§22). Slot labels describe relevance ("For you today", "To explore"),
   never assessment.
3. Home cards and features pass the same banned-phrase, diagnostic-implication,
   and contraception-boundary checks as article bodies (§§10.2, 12–14, 18,
   21.1, 26): contextual introductions use pattern language only.
4. Pregnancy-gated articles (§§6.6–6.7, 15) are library-only unless explicit
   pregnancy state exists; they are never pushed into Home slots by lateness,
   symptoms, or estimates.

---

## 38. Insights tab (dedicated library destination)

### 38.1 Purpose

The Insights tab is the **complete collection/discovery experience**
(INSIGHTS LIBRARY, §36.3): every published article browsable and searchable
by every user. Personalization reorders the For You shelf; it never gates the
rest (§20.1).

### 38.2 Conceptual information architecture (normative structure, not pixel spec)

```text
INSIGHTS
│
├── For You
│   └── contextually relevant content (§§20–22; "Suggested because…"
│       reasons visible; full library still reachable below)
│
├── Featured
│   └── editorial/magazine stories (Editorial Features, §45; curated,
│       rotated for freshness/diversity — never urgency-ranked)
│
├── Explore
│   ├── Menstrual Cycle
│   ├── Ovulation & Fertility
│   ├── Cycle Tracking
│   ├── Symptoms & Wellbeing
│   ├── Reproductive Health
│   ├── Pregnancy
│   ├── Pregnancy & Body
│   ├── Reproductive Aging
│   ├── Contraception
│   └── Mind, Society & Health
│
└── Latest / More to Explore
    └── recency-ordered published articles + continued browsing
```

Notes:

1. This is a **conceptual IA**: 6B implements the shelves and their
   responsibilities, not a mandatory pixel-level layout. Visual design keeps
   MenoMate identity (§44).
2. Explore categories map 1:1 to the §6 taxonomy slugs
   (`menstrual-cycle`, `ovulation-fertility`, `cycle-tracking`,
   `symptoms-wellbeing`, `reproductive-health`, `pregnancy`,
   `pregnancy-body`, `reproductive-aging`, `contraception`,
   `mind-society-health`). Category pages list that category's articles from
   the same bodies (§46) — no per-surface copies.
3. Explore is always fully browsable: a user with no recorded data sees the
   same categories and articles, in default order.
4. For You and Featured never resolve to conditions (§14): no
   symptom-to-condition matching in ranking, search, or shelf construction.
5. Pregnancy categories (§§6.6–6.7, 15) are browsable library content; only
   *prioritization/push* of them is state-gated, never access.

---

## 39. Article experience (recommended flow)

### 39.1 Recommended article flow (normative order, flexible composition)

```text
Editorial Cover
↓
Title / subtitle / read time
↓
Short plain-language introduction
↓
Visual explanation
↓
Article sections
↓
Callouts / key facts / diagrams where useful
↓
Evidence/source information
↓
Safety / when-to-seek-care
↓
Related Insights
```

### 39.2 Rules

1. **Do not force every article to use every block.** The renderer composes
   from the §23.2 block set per article (cover, introduction, sections,
   callouts, key facts, timelines, comparisons, illustrations, checklists,
   myth-vs-fact, when-to-seek-care, sources). Short explainers may use a
   subset; long-form uses more. The `sources` and `safety` positions are the
   only non-optional ones (every article, §§25–26).
2. The renderer supports **different article structures** from one engine:
   block order follows the flow above by default; articles may insert
   additional visual-explanation or callout positions where the topic needs
   them, without inventing new block semantics outside §23.2.
3. The introduction states plainly what the article will and won't do
   (uncertainty posture + scope, §23.2 `introduction`); the visual
   explanation early in the flow previews the concept the sections then teach
   in words (§40).
4. Evidence/source information is rendered from registry metadata (§25),
   adjacent to the claims it supports where practical, with the full source
   list at the article's evidence position — never a bare link dump.
5. Safety / when-to-seek-care (§§26–27) is a structural position, not an
   afterthought: disclaimers stay specific and proximal; red-flag blocks are
   referenced from the shared library (`RFB-…`), not rewritten per article.
6. Related Insights links to general-context articles only (§14): never
   "your explanation" linkages, never condition-match ranking.

---

## 40. Visual storytelling (explicit product requirement)

### 40.1 Requirement

MenoMate Insights **must** support educational content that combines prose
with visual explanation. Supported visual explanations include (non-exhaustive,
composed per article — never all at once):

- illustrations and symptom illustrations
- diagrams and comparison graphics
- timelines (cycle, transition, gestational-age-informational)
- simplified anatomy (patient-education accuracy, §24.4)
- cycle visualizations and hormone timelines (typical patterns with
  variation bands, never exact personal curves)
- fertility-window illustrations (population schematic, never a personal
  calendar — §§10, 24.2)
- myth-vs-fact visuals
- reproductive-aging timelines

### 40.2 The goal (normative formula)

The goal is NOT to replace text with images. The goal is:

```text
VISUAL HOOK
+
PLAIN-LANGUAGE EXPLANATION
+
DEEPER VISUAL EXPLANATION
```

- The **visual hook** (cover/hero) invites reading.
- The **plain-language explanation** teaches the concept in words first.
- The **deeper visual explanation** (inline diagram/timeline/comparison)
  reinforces the words with structure readers can scan and remember.

### 40.3 Text-alongside-visual rule (normative)

Important visuals **normally have supporting text** so users never need to
interpret medical graphics without context:

1. Every informational visual has a caption stating what it shows **and its
   limits** ("Illustrative pattern — individual timing varies") plus
   `scientific_context` (what it is based on + what it must not be read as),
   per §§24.2–24.3/42.
2. The surrounding body text restates the visual's teaching in words: the
   article remains fully understandable if the visual fails to load or the
   reader uses a screen reader (§41).
3. No visual may imply diagnosis, guarantee outcome, or contraceptive
   protection (§§10.2, 12–14, 18, 24.4) — visuals pass the §26 checklist and
   §28 review with the same rigor as sentences.

---

## 41. Text inside visuals (typography as composition)

### 41.1 Allowed

Editorial artwork **may integrate typography into the visual composition**.
An Editorial Cover may contain, as part of its design:

- article title
- short subtitle
- category label
- small supporting phrase (e.g. topic framing, series name)

Large typography in Editorial Features (§45) works the same way: display text
composed with illustration, not body copy baked into pixels.

### 41.2 Accessibility and meaning rules (normative)

1. **Accessibility text still exists separately.** Every visual with composed
   text carries `alt_text` (full textual equivalent) and, where the cover
   text differs from the article title, the accessible name matches the
   article's semantic title — not a transcription of decorative line breaks.
2. **Important medical information must not exist ONLY inside an image.**
   Any teaching, number, threshold, instruction, or warning that matters is
   also present as real semantic text in the article body (or safety block),
   where it is searchable, selectable, translatable, and screen-reader
   reachable.
3. **Article meaning remains accessible without the artwork.** Covers, heroes,
   and feature art are progressive enhancement: removing every image leaves a
   complete, coherent, safe article (titles, introductions, sections,
   captions' limit-statements preserved in text).

---

## 42. Visual asset model (expands §24.3)

### 42.1 Metadata (normative field set — superset of §24.3)

Each visual asset carries:

- `asset_id` — stable ID (`VIS-…`); never reused.
- `role` — one of §42.2 (what the asset is *for*).
- `type` — image / illustration / diagram / infographic / timeline / chart
  (what the asset *is*; orthogonal to role).
- `aspect_ratio` — e.g. `1:1`, `4:3`, `16:9`, `9:16` (declared so Card, Cover,
  Hero, and Inline slots can select correctly without cropping meaning away).
- `alt_text` — full textual equivalent (accessibility; reviewed like body
  copy, §28).
- `caption` — visible caption including limits where the visual is
  informational (e.g. "Illustrative pattern — individual timing varies").
- `scientific_context` — what the visual is based on + what it must not be
  read as (required for diagrams, timelines, window schematics, anatomy).
- `source` — source ID(s) from §29 for data-driven visuals (empty only for
  purely decorative compositions, which must then be marked decorative).
- `licensing_status` — origin + license/permission state; no unlicensed
  clinical imagery.
- `attribution` — visible credit where the license requires it.
- `decorative_vs_informational` — exactly one flag: `decorative` (ambience
  only, carries no teaching, still needs alt handling per platform menée —
  null/empty-alt only if truly meaning-free) or `informational` (carries
  teaching → full caption + context + sourced, §§24.2, 40.3).
- `generated_vs_external` — `generated` (MenoMate-commissioned/generated for
  the article; reviewed for medical misinformation per §24.4) or `external`
  (licensed/acquired; source + license verified at review).
- `version` — asset revision; cover/hero/inline swaps re-open the article to
  `CLINICAL_REVIEW` if the visual carries meaning (§31.2 backward
  transitions), editorial-only crops do not.

### 42.2 Roles (normative vocabulary)

- `COVER` — editorial cover composition (§36.3; feed/library/feature use).
- `HERO` — hero artwork at article open (§36.3).
- `THUMBNAIL` — small card/list image (may reuse cover art at small size;
  legibility of composed text at small sizes must be verified — covers with
  fine typography need a simplified thumbnail variant, not a crushed crop).
- `INLINE_ILLUSTRATION` — explanatory illustration inside the body.
- `DIAGRAM` — mechanism/structure explanation (cycle, anatomy, marker logic).
- `INFOGRAPHIC` — combined fact-graphic (only for `GUIDELINE_SUPPORTED` or
  stronger claims; every fact on the graphic resolves to a claim ID).
- `TIMELINE` — sequence over time (cycle phases, transition, dating
  concepts — ranges and variation stated, no guarantees).
- `FEATURE_ARTWORK` — large magazine-story art (full-screen cover,
  sequential story panels, §45).

### 42.3 Rules

1. **Do not require every article to have all asset types.** Minimal viable
   article: one `COVER` (+ derived `THUMBNAIL`) and, where the topic warrants
   it, one `HERO` (may reuse cover composition at hero ratio) — inline and
   feature art only where they add explanation (§40).
2. Roles are presentation assignments (§46): the same illustration file may
   serve `COVER` in the library and `HERO` in the article via separate asset
   records (separate ratios/crops), never by forking article content.
3. Infographics, diagrams, and timelines with numbers require
   `CURRENT_GUIDANCE`-or-stronger backing for the numbers (§§3, 18) +
   clinical review; qualitative schematics state their qualitative nature in
   caption and context.

---

## 43. Responsive presentation (one body, many surfaces)

The same Insight appears differently by context — from the **same article
body** (§46):

| Context | Presentation |
|---|---|
| Home (standard) | Compact Insight Card (§37.2 A–B) |
| Home (featured) | Editorial Feature (§37.2 C; richer cover + large type) |
| Insights library | Cover / card grid rows (§38) |
| Opened article (top) | Hero Artwork (§36.3) |
| Inside article | Inline visual / diagram (§36.3) |

Rules (normative):

1. **Do not duplicate article content merely because presentation differs.**
   Surfaces select presentation config (which cover ratio, whether to show
   the feature treatment, which inline assets to place) over one body.
2. Claim, source, and safety metadata are presentation-independent: a card
   never teaches what the article hedges, and a feature never promises what
   the article leaves uncertain.
3. Cards and covers show honestly computed `estimated_read_time` and category;
   they never show scores, probabilities, or verdicts (§22).

---

## 44. Editorial design principles (normative)

MenoMate's editorial visual language is:

- **approachable** — plain words first, inviting visuals, no intimidation;
- **calm** — steady tone and palette; urgency only inside marked red-flag
  blocks (§27);
- **modern** — contemporary type and composition, readable on current phones;
- **editorial** — magazine-like covers, features, and pacing (§§36, 45), not
  a settings-screen list of links;
- **visually expressive** — illustration, diagram, and timeline craft in
  service of explanation (§40), not decoration-as-authority;
- **scientifically responsible** — every visual claim sourced, hedged, and
  reviewed (§§24.4, 28, 40.3);
- **readable on mobile** — type sizes, contrast, line length, and touch
  targets for small screens; composed cover text legible at card size or
  given a simplified variant (§42.2 `THUMBNAIL`);
- **not overly clinical** — no textbook coldness, no alarming imagery;
- **not childish** — no cartoonish trivialization of serious topics;
- **not dependent on stereotypical pink/feminine styling** — identity must
  work without gender-stereotyped color or motif reliance;
- **visually varied** — covers and features differ across topics and over
  time (rotation/diversity, §§22, 37–38), avoiding a wall of identical cards;
- **consistent MenoMate identity** — varied but recognizably one product:
  shared type scale, spacing, corner/shape language, and cover-grid logic
  defined once in 6B and reused.

Directional visual references discussed during product planning are
**inspiration only**: they inform taste (approachability, pacing, craft),
never supply layouts, components, artwork, or styles to reproduce. Do not
reproduce another company's design system, illustration library, or brand.

---

## 45. Magazine stories (Editorial Feature format)

### 45.1 Definition

An Editorial Feature / Magazine Story is a **supported presentation format**,
not a separate content type. It may include:

- full-screen cover
- multi-section visual story (sequential illustrations/panels)
- large typography composed with art (§41)
- short sections (same §23.2 blocks, shorter bodies, more visual beats)
- visual explanations inline with each beat (§40)
- interactive-feeling progression where appropriate (paged/scroll-stepped
  pacing through the *same* blocks — progress UI only, no branching logic,
  no quizzes resolving to conditions per §14)

### 45.2 Rules (normative)

1. **Do not build a separate article engine.** A Magazine Story **remains an
   Insight Article** (same `id`/`slug`, same claim set, same sources, same
   safety components) with a richer **presentation configuration**
   (feature flag + panel order + feature artwork set, §46).
2. Feature pacing never drops required positions: introduction, evidence, and
   safety/when-to-seek-care (§39) appear in every Magazine Story, however
   visual the treatment.
3. Sequential panels each pass the text-alongside-visual rule (§40.3):
   no meaning carried by art alone across a swipe boundary.
4. Personalization, provenance, and review rules apply unchanged: features
   are prioritized like any article (§§20–22), carry the same provenance
   (§5), and publish through the same §28 gate (§31.2).

---

## 46. Content vs presentation (load-bearing separation)

### 46.1 Definitions (normative)

- **CONTENT MODEL** — *What the article says.* The `Insight` body (§23.1):
  title/subtitle/category, ordered content blocks, claim-backed sentences,
  evidence/source metadata, safety components, personalization rules. Owned
  by curation + clinical review (§28). Changes re-open review.
- **PRESENTATION MODEL** — *How that content is surfaced/rendered.* Which
  card/cover/hero/inline/feature configuration renders the body on a given
  surface (Home card vs Home feature vs library cover vs article hero vs
  inline diagram — §43), plus purely presentational choices (ratios, crops,
  type scale, panel pacing). Owned by design/engineering. Presentational
  changes that carry no meaning (crop, ratio, ordering of equal-weight
  browse shelves) do not re-open clinical review; any change that alters
  teaching, emphasis of a claim, or safety adjacency does (§42.1 `version`).

### 46.2 Reuse rule (normative)

One article body is reusable across **Home, Insights library, category
pages, featured sections, and article detail** without copying:

```text
CONTENT (one body) ──references──▶ PRESENTATION (many configs)
  Insight.body                        Home card config
  Insight.claims                      Home feature config
  Insight.sources                     Library cover config
  Insight.safety                      Category row config
                                      Article hero + inline config
                                      Magazine-story config
```

**Do not duplicate the article body for each surface.** Surfaces store
presentation references (article `id`/`slug` + asset `asset_id`s + slot
config), never body copies. A correction to a sentence, claim, caption, or
red-flag reference updates every surface at once (with re-review per §31.2
where meaning changed).

---

## 47. Non-goals for this architecture (do not overengineer)

The §§36–46 editorial experience is implementable without any of the
following. All are **explicitly out of scope** for 6A/6B:

- **CMS infrastructure** — no hosted editor, workflow backend, roles/permissions
  service, or content API. Curation happens in reviewed source files feeding
  the typed local registry.
- **Server-side content management** — no remote authoring, staging, or
  publish pipeline. Phase 6B ships bundled content (offline-first,
  `lib/content/` pattern); architecture only *leaves room* for future remote
  delivery (stable `id`/`slug`/`asset_id`/`source_id` keys, `version` fields,
  and the content/presentation split in §46 make a future fetch-and-cache
  layer additive, not a rewrite).
- **Complex recommendation ML** — no learned rankers, embeddings, or
  behavioral models. Ranking stays transparent, score-free, and documented
  (§22): coarse bands + explicit flags + freshness/diversity.
- **Analytics platform** — no event pipeline, funnels, or experimentation
  framework in this architecture. (If product analytics ever arrives, it
  measures surface usage, never trains medical conclusions.)
- **Medical decision support** — no triage, risk stratification, staging
  logic, or eligibility engines in content, ranking, search, or visuals
  (§§12–14, 17, 22).
- **AI-generated medical content pipeline** — no LLM-authored claims, visuals
  with invented medicine, or auto-published drafts. The select-then-enhance
  posture stands: the deterministic library is authoritative; any future AI
  surround passes full §28 review before reaching users (§33.2).

Phase 6B therefore begins with a **strongly typed local content registry**
(article + claim + source + asset + red-flag-block records per
§§7, 23.1, 29.1, 31.1, 42.1) bundled with the app — and nothing heavier.

---

## 48. Editorial final review (Phase 6A exit check for §§36–47)

After §§36–47, the specification holds only if each item below is true
(extends §34; self-check, code authoritative, nothing edited but this file):

1. Evidence architecture intact (§§3, 7, 25, 29): claims still resolve to
   pinned sources; no presentation surface teaches unsourced claims.
2. Clinical review separate from evidence status (§§4, 28): covers, heroes,
   inline visuals, and feature panels pass the same per-claim-in-article
   review; presentational tweaks never substitute for it.
3. Provenance explicit (§5): no presentation or personalization step upgrades
   `OBSERVED → ESTIMATED → CLINICALLY_CONFIRMED` or presents
   `EVIDENCE_SUPPORTED` as a statement about the reader.
4. Fertility/TTC safety intact (§§9–11, 18): window taught as population
   approximation; banned language enforced in bodies, cards, covers,
   visuals, and metadata; estimates never contraception.
5. Pregnancy mode deferred (§15): content never enters/exits/modifies
   pregnancy mode; no dating math in content; legacy context unreinterpreted.
6. Prediction algorithms frozen (§11.2, §33.2): no retune/re-derive/
   reimplement in content, visuals, or 6B code.
7. No diagnostic functionality introduced (§§12–14, 20.3, 21–22): no
   classifiers, quizzes-to-condition, symptom-matched ranking/search, or
   "your explanation" linkage in any surface including Features.
8. Editorial presentation formally defined (§36): all seven terms
   (Insight Card, Editorial Cover, Hero Artwork, Inline Visual, Editorial
   Feature, Insight Article, Insights Library) defined; one-body-many-forms
   rule stated.
9. Home vs Insights responsibilities separated (§§37–38): Home = discovery
   sample (Today's + supporting + occasional feature + See All); Insights =
   full library (For You / Featured / Explore / Latest); personalization
   surfaces-first without gating.
10. Content vs presentation separated (§46): reuse rule stated; no body
    duplication across surfaces; correction propagation described.
11. Visual accessibility explicit (§§40.3, 41–42): alt text, semantic text,
    readable mobile type; important information never image-only; meaning
    survives artwork removal.
12. Magazine/editorial stories supported without a second engine (§45):
    feature = article + richer presentation config; required
    evidence/safety positions preserved.
13. Phase 6B has a concrete implementation contract (§33.1–§33.3): content,
    presentation, discovery, personalization, and accessibility tracks each
    list shippable 6B work inside the §33.2 forbiddens.
14. No overengineering (§47): CMS, server content management, recommendation
    ML, analytics, decision support, and AI content pipeline all deferred;
    6B starts from the typed local registry with remote-delivery room left
    open.

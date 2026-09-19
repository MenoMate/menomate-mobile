# MenoMate Reproductive Evidence Library (Phase 0 — Documentation Only)

> Status: **Phase 0 structured evidence registry.** Normative companion to
> `docs/reproductive-health-spec.md` (§8) and `docs/reproductive-safety-boundaries.md`.
> Documentation only — no code, schema, API, or behavior change.
>
> Rules for this registry:
>
> - Do NOT put full papers/PDFs into the application.
> - Do NOT copy long passages from papers. Each entry carries a **short reviewed claim**
>   (1–3 sentences, paraphrased) plus product implication and limitations.
> - Every entry needs: Evidence ID, Topic, Short reviewed claim, Source,
>   Publication/year, URL or identifier where available, Product implication, Limitations.
> - New reproductive product copy, Care responses touching reproduction, and reproductive
>   Insights must trace to an entry here. If no entry supports a claim, the claim does
>   not ship.
> - Entries marked `NEEDS-REVIEW` are authoritative-source placeholders recorded honestly
>   as unverified in Phase 0. A clinician/curator must verify each short claim against the
>   cited source before any Phase 2+ implementation relies on it. Nothing below is a
>   substitute for reading the source.
> - This registry is curated product-evidence metadata, not a bibliography of everything
>   read. Prefer guidelines and systematic reviews over single studies.

---

## How to read an entry

| Field | Meaning |
|---|---|
| Evidence ID | Stable ID (`EV-<TOPIC>-<NNN>`). Product copy cites this ID in review, never inline prose from the source. |
| Topic | One of the 8 required coverage topics. |
| Short reviewed claim | Paraphrased 1–3 sentence claim. Short enough to review, never a passage copy. |
| Source | Guideline body / journal / institution. |
| Publication/year | Edition or publication year (or "living guideline — verify current edition"). |
| URL / identifier | Link, DOI, or catalog ID where available. |
| Product implication | What MenoMate may/must do (or not do) because of this evidence. |
| Limitations | Why the evidence does not license stronger product claims. |

---

## A. Menstrual-cycle physiology

### EV-PHYS-001 — NEEDS-REVIEW

- **Topic:** Menstrual-cycle physiology
- **Short reviewed claim:** Menstrual cycles vary between individuals and between cycles
  in the same individual; cycle length, bleeding duration, and phase timing are not fixed
  constants.
- **Source:** ACOG (American College of Obstetricians and Gynecologists) — menstruation
  patient-education / committee resources (exact FAQ/opinion number to be pinned at review).
- **Publication/year:** Living guideline — verify current edition at Phase 1.
- **URL / identifier:** https://www.acog.org — pin exact FAQ URL at review.
- **Product implication:** Licensed: variability-aware copy ("cycles vary month to
  month"); confidence states that degrade with variability (spec §4, §7.4). Forbids:
  fixed-day assumptions presented as fact.
- **Limitations:** Patient-education material summarizes consensus; does not provide
  model parameters. Cannot license any numeric rule by itself.

### EV-PHYS-002 — NEEDS-REVIEW

- **Topic:** Menstrual-cycle physiology
- **Short reviewed claim:** The luteal phase (post-ovulation to next menses) is
  relatively less variable than the follicular phase; most cycle-length variability comes
  from the pre-ovulatory portion.
- **Source:** Reproductive-endocrinology textbook / review literature (exact source to be
  pinned at review — candidate: standard cycle-physiology reviews).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Informs (but does not by itself license) future estimate
  design in Phase 2; any numeric use requires its own evidence entry + contract review.
- **Limitations:** Population-level tendency with wide individual spread; cannot license
  per-user day-count rules. Phase 0 invents no numbers from this.

---

## B. Ovulation timing

### EV-OVUL-001 — NEEDS-REVIEW

- **Topic:** Ovulation timing
- **Short reviewed claim:** Ovulation timing varies between individuals and across
  cycles; it cannot be fixed to a single canonical cycle day for all users.
- **Source:** Cycle-variability cohort literature (exact study/review to be pinned at
  review — candidate: large prospective cycle-cohort analyses).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review (DOI at review).
- **Product implication:** Licensed: estimated (never guaranteed) ovulation; required
  confidence states; banned guaranteed-date language (spec §4, §5).
- **Limitations:** Cohort distributions do not predict any individual's cycle; cannot
  license personalized day counts without per-user evidence.

### EV-OVUL-002 — NEEDS-REVIEW

- **Topic:** Ovulation timing
- **Short reviewed claim:** Cycle irregularity increases the uncertainty of any
  calendar-based ovulation estimate; estimates built on irregular histories are less
  reliable than those built on regular ones.
- **Source:** Fertility-awareness / cycle-variability literature (exact source to be
  pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: `LOW_CONFIDENCE` / `INSUFFICIENT_DATA` behavior and
  the variability-degrades-confidence rule (spec §3.3, §4, §7.4).
- **Limitations:** Supports the *direction* (more variability → less certainty), not any
  specific threshold. Thresholds are Phase 1/2 contract decisions requiring their own
  review.

---

## C. Fertile-window biology

### EV-FERT-001 — NEEDS-REVIEW

- **Topic:** Fertile-window biology
- **Short reviewed claim:** Conception probability is concentrated in a multi-day window
  ending around ovulation, reflecting sperm survival of several days and short ovum
  viability; probability is not uniform across the window.
- **Source:** Prospective conception-probability cohort literature (exact study to be
  pinned at review — candidate: Wilcox et al., conception-probability cohorts).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review (DOI at review).
- **Product implication:** Licensed: an *estimated* fertile *window* (a span, not a day)
  presented with estimate wording. Forbids: single "fertile day" guarantees,
  safe/unsafe-day framing (spec §5).
- **Limitations:** Population probabilities; cannot license per-user fertile/infertile
  guarantees or contraceptive use. Phase 0 sets no window width.

### EV-FERT-002 — NEEDS-REVIEW

- **Topic:** Fertile-window biology
- **Short reviewed claim:** Calendar/rhythm-type methods that rely on past cycle lengths
  alone have meaningful failure rates and are among the least reliable approaches when
  used to avoid pregnancy.
- **Source:** Contraceptive-effectiveness literature / CDC contraceptive guidance
  (exact source to be pinned at review).
- **Publication/year:** Verify current edition at review.
- **URL / identifier:** https://www.cdc.gov — pin exact resource at review.
- **Product implication:** Licensed (required): the ban on contraceptive framing and the
  "calendar predictions cannot guarantee contraception" rule (spec §5; safety
  boundaries §3).
- **Limitations:** Effectiveness figures depend on correct/consistent use definitions;
  this entry licenses only the *negative* claim (do not present as contraception), never
  any positive efficacy number in product copy.

---

## D. Fertility-awareness methods

### EV-FAM-001 — NEEDS-REVIEW

- **Topic:** Fertility-awareness methods
- **Short reviewed claim:** Formal fertility-awareness methods combine multiple observed
  signs (e.g. cervical mucus, basal body temperature, LH, calendar rules) under strict
  protocols; their published performance depends on those protocols, not on any single
  sign or on casual calendar use.
- **Source:** Fertility-awareness / family-planning literature (exact method manual or
  review to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: treating LH/BBT/mucus as *evidence inputs* with
  distinct semantics (spec §3.6), never as standalone answers. Forbids: presenting one
  signal as a complete fertility answer.
- **Limitations:** Method-specific results do not transfer to app estimates automatically;
  MenoMate is not a certified fertility-awareness method and must never claim to be one.

---

## E. Ovulation detection methods

### EV-DETECT-001 — NEEDS-REVIEW

- **Topic:** Ovulation detection methods
- **Short reviewed claim:** Urinary LH surges precede ovulation and are used as a
  prospective indicator that ovulation may follow within a short interval; surge-to-
  ovulation timing varies and not every surge is followed by ovulation.
- **Source:** Ovulation-detection / reproductive-endocrinology literature (exact source
  to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review (DOI at review).
- **Product implication:** Licensed: LH as a *prospective ovulation-related signal*
  (spec §3.6). Forbids: rendering a positive LH test as an ovulation date or guarantee.
- **Limitations:** Test sensitivity, timing, and conditions (e.g. PCOS-related LH
  patterns) limit interpretation; no per-user prediction rule follows from this entry
  alone.

### EV-DETECT-002 — NEEDS-REVIEW

- **Topic:** Ovulation detection methods
- **Short reviewed claim:** A sustained basal-body-temperature rise is a retrospective
  marker consistent with ovulation having occurred; it cannot predict ovulation in
  advance and requires repeated correct measurement to interpret.
- **Source:** BBT / fertility-awareness literature (exact source to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: BBT as *retrospective* evidence (spec §3.6).
  Forbids: any prospective "BBT predicts ovulation" framing.
- **Limitations:** Confounded by illness, sleep disruption, alcohol, measurement error;
  single readings are uninterpretable. Supports only the *direction* of use (look
  backward), not any algorithm.

### EV-DETECT-003 — NEEDS-REVIEW

- **Topic:** Ovulation detection methods
- **Short reviewed claim:** Fertile-type cervical mucus observations are associated with
  the approaching fertile window and are used prospectively in fertility-awareness
  protocols; they are subjective observations, not measurements of ovulation itself.
- **Source:** Cervical-mucus / fertility-awareness literature (exact source to be pinned
  at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: mucus as a *prospective fertility-related
  observation* (spec §3.6). Forbids: rendering mucus observations as ovulation
  confirmation.
- **Limitations:** Subjective categorization; inter-user variability; cannot license
  confirmation language or standalone predictions.

---

## F. Pregnancy dating

### EV-DATE-001 — NEEDS-REVIEW

- **Topic:** Pregnancy dating
- **Short reviewed claim:** First-trimester ultrasound crown–rump length is the most
  accurate single method for establishing gestational age and estimated due date, and
  clinical guidance prefers it over LMP-based dating when available.
- **Source:** ACOG Practice guidance on pregnancy dating / ultrasound dating criteria
  (exact bulletin/practice advisory number to be pinned at review).
- **Publication/year:** Living guideline — verify current edition at Phase 1.
- **URL / identifier:** https://www.acog.org — pin exact resource at review.
- **Product implication:** Licensed: the dating hierarchy §6.4 (clinician dating >
  first-trimester ultrasound > LMP estimate) and the never-silently-override rule.
- **Limitations:** Guideline recommendations assume clinical measurement quality;
  dating precision degrades with later-gestation measurement. Licenses hierarchy only,
  not any app-side dating computation.

### EV-DATE-002 — NEEDS-REVIEW

- **Topic:** Pregnancy dating
- **Short reviewed claim:** LMP-based dating assumes regular cycles with ovulation at a
  typical mid-cycle point; irregular cycles, recent hormonal contraception, and uncertain
  LMP recall reduce its accuracy.
- **Source:** Pregnancy-dating literature / ACOG dating guidance (exact source to be
  pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: LMP dating as fallback *estimate* with confidence
  treatment (spec §6.4); clinician dating preserved over it.
- **Limitations:** Supports only the fallback positioning, not any correction formula.
  No app-side re-dating math is licensed by this entry.

---

## G. Pregnancy recognition

### EV-PREG-001 — NEEDS-REVIEW

- **Topic:** Pregnancy recognition
- **Short reviewed claim:** A missed/late period is a common early reason to consider
  pregnancy testing, but it is nonspecific: stress, illness, weight change, travel,
  perimenopause, and ordinary cycle variability also cause late or missed periods.
- **Source:** Clinical pregnancy-diagnosis references / ACOG patient education (exact
  source to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed (required): the no-inference-from-late-period rule —
  pregnancy mode is user-controlled; at most a neutral test/logging suggestion (spec
  §6.1). Forbids: any "you may be pregnant" conclusion from cycle data.
- **Limitations:** Licenses only restraint (what the product must *not* conclude), not
  any diagnostic or triage behavior.

### EV-PREG-002 — NEEDS-REVIEW

- **Topic:** Pregnancy recognition
- **Short reviewed claim:** Urine pregnancy tests detect hCG with accuracy that depends
  on timing relative to missed menses and on test sensitivity; testing too early can
  produce false negatives, and positive results warrant clinical confirmation and dating.
- **Source:** Pregnancy-test / hCG diagnostics literature or manufacturer-independent
  clinical guidance (exact source to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: recording test results as OBSERVED data (spec
  §2.1); neutral guidance to confirm positives with a clinician. Forbids: diagnosing
  pregnancy from an app-recorded test alone.
- **Limitations:** Sensitivity/specificity figures are test- and timing-specific; no
  numbers ship in product copy from this entry.

---

## H. Perimenopause / menopausal transition

### EV-PERI-001 — NEEDS-REVIEW

- **Topic:** Perimenopause/menopausal transition
- **Short reviewed claim:** The menopausal transition is characterized by increasing
  menstrual-cycle variability and persistent changes in cycle length and bleeding
  patterns, unfolding over years; staging systems (e.g. STRAW+) define stages by
  bleeding-pattern criteria, not by any single cycle.
- **Source:** STRAW+ staging criteria (Harlow et al.) and/or NAMS/IMS menopause guidance
  (exact source to be pinned at review).
- **Publication/year:** To be pinned at review (STRAW+ 2011; verify current guidance).
- **URL / identifier:** To be pinned at review (DOI at review).
- **Product implication:** Licensed: trend-based contextual signals (spec §7.2) and the
  contextual-not-diagnostic architecture (spec §7.1). Forbids: stage labels or
  perimenopause diagnosis from app data.
- **Limitations:** Staging criteria are clinical tools requiring history a consumer app
  cannot fully establish; no staging logic is licensed for MenoMate.

### EV-PERI-002 — NEEDS-REVIEW

- **Topic:** Perimenopause/menopausal transition
- **Short reviewed claim:** Vasomotor symptoms, sleep disturbance, and mood changes are
  commonly reported during the transition but are nonspecific and also occur for many
  other reasons; they do not by themselves establish menopausal stage.
- **Source:** NAMS / IMS guidance or systematic review of transition symptoms (exact
  source to be pinned at review).
- **Publication/year:** To be pinned at review.
- **URL / identifier:** To be pinned at review.
- **Product implication:** Licensed: logging such symptoms as verbatim user-reported
  context (spec §7.2); cautious pattern language (spec §7.3). Forbids: treating symptom
  reports as diagnostic criteria.
- **Limitations:** Symptom epidemiology cannot license any individual-level conclusion;
  supports only the logging-plus-cautious-language design.

---

## Registry maintenance

- Additions require all eight fields. New entries default to `NEEDS-REVIEW` until a
  curator verifies the short claim against the source.
- `NEEDS-REVIEW` entries must be verified (or replaced) before the Phase that relies on
  them: §§A–E before Phase 2, §F–G before Phase 3, §H before Phase 4.
- Corrections append a dated note to the entry; IDs are never reused.
- The banned-phrase and no-guarantee rules (`docs/reproductive-safety-boundaries.md`)
  hold regardless of what any future entry says — evidence can only narrow product
  claims, never widen them past the safety boundaries.

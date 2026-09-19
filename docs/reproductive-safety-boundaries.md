# MenoMate Reproductive Safety Boundaries (Phase 0 — Documentation Only)

> Status: **Phase 0 normative safety boundaries.** Binding on all future
> reproductive-health phases (fertility/ovulation, pregnancy mode, reproductive-aging
> context, and any Insight/Care/notification surface touching them).
> Companion to `docs/reproductive-health-spec.md` (§§4–7, §9) and
> `docs/reproductive-evidence-library.md`.
>
> Documentation only — no code, schema, API, or behavior change.
>
> Governing principle (inherited from the existing Care safety boundary and Insight
> content rules): MenoMate informs and organizes the user's own recorded information.
> It never diagnoses, never guarantees reproductive outcomes, never substitutes for a
> clinician, and every safety-critical limitation is stated in the UI rather than
> implied by its absence.

---

## 1. Prohibited outputs (normative)

MenoMate must NOT:

1. **Diagnose medical conditions** — including, without limitation, PCOS,
   endometriosis, thyroid disorders, or any condition inferred from cycle patterns,
   symptoms, or medications. User-reported conditions are stored verbatim and displayed
   as the user's own statements, never as detections (existing Health Context boundary,
   unchanged).
2. **Diagnose pregnancy automatically** — a late/missed period, a symptom pattern, or
   any model output must never become a pregnancy conclusion. Pregnancy mode is entered
   only by explicit user action (spec §6.1).
3. **Diagnose infertility** — difficulty conceiving, irregular patterns, or age-related
   context must never be rendered as an infertility diagnosis or a fertility verdict.
4. **Diagnose perimenopause** — reproductive-aging signals are a contextual layer only
   (spec §7). No stage labels, no "you are perimenopausal" (see §4 below).
5. **Guarantee ovulation dates** — ovulation values are estimates with confidence
   states (spec §4), always estimate-worded, never guaranteed.
6. **Guarantee fertile/infertile days** — no "safe days", "unsafe days", "guaranteed
   fertile days", or "guaranteed infertile days" (see §3 below).
7. **Guarantee contraception** — the product must not claim, explicitly or by
   implication, that calendar predictions can guarantee contraception or pregnancy
   prevention (see §3 below).
8. **Guarantee conception** — no "you will conceive on…", no conception promises
   attached to fertile-window or ovulation surfaces.
9. **Replace clinician-established pregnancy dating** — clinician dating is preserved
   verbatim and never silently overridden by LMP re-estimates or model output
   (spec §6.4).
10. **Provide unsafe treatment recommendations** — no prescriptions, dosages, medication
    or supplement recommendations, hormone-mechanism claims, or "X treats Y" statements.
    (Extends the existing Insight library content rules to all reproductive content.)
11. **Automatically change medical modes based solely on model inference** — entering/
    exiting pregnancy mode, or any future mode with medical significance, requires
    explicit user action. Inference may at most surface a neutral, optional suggestion
    defined by the phase contract — never a silent transition.

Violation handling: any shipped string, Care response path, Insight, or notification
found in breach of §1 is a blocking defect (same severity as a Care disclaimer-footer
failure today), regardless of which phase introduced it.

---

## 2. Mandatory estimate framing

- Every model-derived reproductive value (ovulation date, fertile window, any future
  reproductive estimate) must be labeled as an **estimate** wherever it appears:
  "Estimated …" in the surface itself, with its confidence state visible or one tap away.
- Estimates must never be rendered with the visual or verbal authority of observed
  facts: no definitive date styling without estimate qualifiers, no prominence that
  implies certainty for `LOW_CONFIDENCE` estimates, no estimate shown at all for
  `INSUFFICIENT_DATA` or `SUPPRESSED` (spec §4).
- Fertility estimates are estimates and must never be presented as guaranteed dates.
- Standard disclaimer (required on or linked from every fertile-window/ovulation
  surface; exact placement is Phase 5, text is fixed here):

> "These are estimates based on the cycles and signs you've logged. They can't
> confirm ovulation or guarantee fertile or infertile days. For contraception or
> conception planning, talk to your clinician."

---

## 3. Fertile-window wording inventory

### 3.1 Required

- "Estimated fertile window" (canonical label for the span).

### 3.2 Banned (exact phrases and all paraphrases with the same meaning)

- "safe days"
- "unsafe days"
- "guaranteed fertile days"
- "guaranteed infertile days"
- Paraphrases carrying the same meaning, including but not limited to: "risk-free
  days", "danger days", "100% fertile/infertile", "you can't get pregnant on…",
  "no pregnancy risk on…", "will not conceive on…".

### 3.3 Contraception framing ban

- The product must not claim — explicitly or by implication — that calendar predictions
  can guarantee contraception or pregnancy prevention.
- MenoMate is not a certified fertility-awareness or contraceptive method and must
  never claim, suggest, or imply that it is.
- Scope: UI strings, Care responses touching fertility, Insight content touching
  fertility, notifications (when they exist), exported/shared summaries, and store
  listing copy. Tests must enforce the banned phrases the way Insight library tests
  enforce banned certainty language today (Phase 5/7 deliverable).

---

## 4. Pregnancy-mode safety rules

- **No inference from lateness.** A late period is observed absence of bleeding, not
  evidence of pregnancy (spec §6.1, EV-PREG-001). The product must never state or imply
  "you may be pregnant" from cycle data.
- **User-controlled transitions only.** Pregnancy mode is entered/exited by explicit
  user action. No silent mode changes on model output (§1.11).
- **Suppression set while active** (spec §6.2): ordinary cycle predictions, ovulation,
  fertile window, and next-period prediction are suppressed; the pregnancy timeline
  (gestational age, estimated due date, dating source) becomes the primary context.
  Suppression copy is neutral and implies no medical conclusion.
- **Dating preservation** (§1.9, spec §6.4): clinician-established dating wins over
  every other basis and is never silently replaced. Any change of dating basis requires
  explicit user confirmation naming old → new and source.
- **Test-result restraint:** a user-recorded positive pregnancy test is OBSERVED data,
  not an app diagnosis (EV-PREG-002). Neutral guidance: confirm with a clinician.
  The product must never render "You are pregnant" from an app-recorded test alone —
  pregnancy *mode* reflects the user's stated state; pregnancy as a *medical fact* is
  for the user and their clinician to establish.

---

## 5. Reproductive-aging language safety rules

- **Banned:** "You are perimenopausal." — and all paraphrases: stage labels ("you're in
  stage…"), diagnostic certainty ("you have…", "you're in menopause", "your symptoms
  mean…").
- **Required pattern:** describe the *observed pattern*, optionally note it *can occur*
  in the transition, and direct persistent/concerning changes to a clinician.
  Approved examples (spec §7.3):
  - "Your cycle pattern has become more variable."
  - "These changes can occur during the menopausal transition."
- **Caution direction:** as aging signals increase, fertility estimates degrade toward
  `LOW_CONFIDENCE` / `INSUFFICIENT_DATA` (spec §7.4) — the product becomes less
  assertive, never more diagnostic.
- Single unusual cycles are never meaningful on their own; trend language requires
  sustained patterns (consistent with existing Insight copy and EV-PERI-001).

---

## 6. Signal-semantics safety rules (LH / BBT / mucus)

- **LH:** a positive result is a prospective ovulation-*related* signal, never an
  ovulation date or guarantee (EV-DETECT-001).
- **BBT:** a temperature shift is retrospective evidence ovulation *may have*
  occurred, never a forward prediction (EV-DETECT-002).
- **Cervical mucus:** a prospective fertility-*related* observation, never ovulation
  confirmation (EV-DETECT-003).
- Missing signals lower confidence; they never assert anovulation or infertility.
- No single signal, and no combination of signals, may be rendered as a guarantee of
  ovulation, fertility, or infertility (§1.5–§1.8).

---

## 7. Enforcement notes (for future phases)

- **Server-side computation:** all estimates and confidence states are computed
  server-side and consumed verbatim by the client — extending the existing
  no-client-prediction freeze (spec §1.2). A client-side estimate or confidence
  computation is a boundary violation, not a shortcut.
- **Contract separation:** new reproductive estimate fields must be additive contract
  fields. Redefining the existing `prediction_*` next-period fields' meaning is
  prohibited (spec §4, §11).
- **Test gates (Phase 5/7):** banned-phrase tests for §3.2/§5 language; suppression
  tests (pregnancy mode hides all four prediction surfaces); dating-preservation tests
  (clinician date survives new LMP data); state-machine tests (§4 transitions, including
  monotonic suppression); no-client-math tests extending the current freeze.
- **Evidence traceability:** every non-trivial reproductive claim traces to a
  `docs/reproductive-evidence-library.md` entry. Evidence narrows claims; it can never
  widen them past this document.
- **Care/Insight inheritance:** the existing Care disclaimer footer + AI marker, the
  tiered server-side triage, and the Insight content rules (no certainty/diagnosis/
  prescription language, sourced claims) apply in full to reproductive content. Any
  reproductive Care/Insight path that bypasses them is a blocking defect.
- **Review order:** wording inventories (§§3–5) and dating rules (§4 of this doc) must
  be reviewed with clinical input before Phase 2/3 implementation; `NEEDS-REVIEW`
  evidence entries must be verified before the phase that relies on them (registry
  maintenance section).

# MenoMate Backend Truth — Gaps

Source: `lib/services/api_service.dart`, `lib/models/*`, Drift schema v4.
Rule: UI → Riverpod → Repository → Drift/API. No invented fields.

## Supported today (real persistence)

- Profile: `name`, `usual_cycle_days` (20–45), `usual_period_days` (1–12),
  `theme`, `units`, `timezone` (IANA), `birth_year` + `birth_month` (pair).
  - `POST /api/v1/onboarding/complete`, `GET/PATCH /api/v1/profile`
- Cycles: `period_start`, `period_end?` (+ server ids, lengths, intervals).
  - `GET /api/v1/cycles`, `POST /api/v1/cycles`, `PATCH /api/v1/cycles/{id}`,
    `GET /api/v1/cycles/current`, `POST /api/v1/cycles/current/end`
- Daily logs: `pain?` (null=not provided, 0=no pain), `mood[]`,
  `discharge?`, `flow?`, `symptoms[{symptom_type,severity}]`, `notes?`.
  - `GET /api/v1/logs/{date}`, `POST /api/v1/logs`
- Predictions (server-only): `predicted_next_period`, `days_until`,
  `prediction_status`, `prediction_confidence`, `prediction_source`,
  `phase`, averages. Frontend displays verbatim; never computes.
- Health context (user-provided, verbatim):
  - Singleton: `contraception_method`, `contraception_note` (≤1000),
    `pregnancy_context`, `health_notes` (≤2000). `PUT` full-replacement.
  - Conditions: 12 curated codes + `other`+`custom_label`, `note?`, `is_active`.
  - Medications: free-text `name`, `note?`, `is_active`.
- Care: `POST /api/v1/care/interactions` (tiered, deterministic red-flag
  triage server-side; frontend never reasons medically).
- Devices: `GET/POST /api/v1/devices` (registration only).

## NOT supported — do not fake

### FEATURE: Height
- CURRENT STATUS: Onboarding collects via picker; stored ONLY on-device
  (`menomate.onboarding_ctx.height_cm.<userId>`).
- BACKEND GAP: No column/endpoint/validation.
- REQUIRED DATA MODEL: `profiles.height_cm INT NULL` (or separate table).
- REQUIRED API: Accept/return `height_cm` in onboarding + profile PATCH/GET.
- SYNC IMPLICATION: Pending → PATCH once field exists; unit conversion
  stays display-only.
- FRONTEND WORK: Swap provider write for repository save; keep pickers.

### FEATURE: Weight
- CURRENT STATUS: Same as height (`weight_kg` local-only).
- BACKEND GAP: No column/endpoint.
- REQUIRED DATA MODEL: `profiles.weight_kg INT NULL`.
- REQUIRED API: Same as height.
- SYNC IMPLICATION: Same as height.
- FRONTEND WORK: Same as height.

### FEATURE: Goals (track/understand/conceive/pregnancy/perimenopause)
- CURRENT STATUS: Single-select cards; stored local-only
  (`onboarding_ctx.goal`); only track+understand map to live features.
  Others show "Requires backend support" and change nothing.
- BACKEND GAP: No goals table/endpoint/mode.
- REQUIRED DATA MODEL: `user_goals {user_id, goal_key, created_at}` or
  `profiles.primary_goal`.
- REQUIRED API: `GET/PUT /api/v1/profile/goal` (or goals resource).
- SYNC IMPLICATION: Local-first pending + server-authoritative mode.
- FRONTEND WORK: Gate pregnancy/perimenopause experiences on real flag;
  keep architecture extensible (see `kOnboardingGoals.supportedNow`).

### FEATURE: Fertility / ovulation / fertile window
- CURRENT STATUS: Not shown. Only backend `phase` string displayed;
  `fertility_awareness` exists solely as one contraception enum value.
- BACKEND GAP: No fertile-window/ovulation-date/LH endpoint.
- REQUIRED: Product + clinical decision first; then server-computed
  fields with confidence/source. Never client-computed.
- FRONTEND WORK: Render server spans with distinct style + legend.

### FEATURE: Pregnancy mode / perimenopause mode
- CURRENT STATUS: `pregnancy_context` enum stored verbatim; explicitly
  does not change predictions (see reproductive screen copy).
  No perimenopause field at all.
- BACKEND GAP: No due-date/trimester/mode; no menopause-stage/HRT.
- REQUIRED: New tables/endpoints + safety review.
- FRONTEND WORK: Dedicated modes only after contract lands.

### FEATURE: Reminders / notifications
- CURRENT STATUS: None. No scheduling, push-token (beyond devices),
  or preference UI.
- BACKEND GAP: No reminder endpoint/table.
- REQUIRED: Notification prefs + scheduling contract.
- FRONTEND WORK: Settings section + permission flow after backend.

### FEATURE: Additional reproductive features
- Same rule: document contract first; never invent API fields,
  predictions, or persistence. The onboarding reproductive step only
  writes the two supported enums via the real health-context repo.

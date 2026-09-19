# MenoMate Mobile

Flutter client for MenoMate: cycle tracking UI, offline-first daily logging, server-driven predictions display, deterministic Daily Insight, Care chat, and BLE wearable plumbing. Backend: [MenoMate_core](../MenoMate_core/README.md) (FastAPI, the only database access layer).

> Status labels: **implemented** (shipped in the app), **partial** (scaffolded, not end-to-end), **planned** (agreed, not built).

## Overview

What the app does today: onboarding → Supabase Auth session → Home (cycle ring, status, Daily Insight, wellness + wearable cards) → History (calendar + cycles panes) → Care chat → Settings, all working offline-first against a local Drift/SQLite store that syncs to FastAPI when reachable.

## Architecture

```text
UI (screens/widgets)
  → Riverpod providers (same names as before, DataState values)
    → repositories (cycle / daily-log / profile)
      → Drift/SQLite locally (pending rows) + FastAPI remotely (sync)

Flutter handset <--BLE--> ESP32 wearable (partial: scan works, commands stubbed)
```

Boundaries that must stay intact:

- The app performs **no prediction or phase math** — it displays server values and caches them. There is deliberately no second local prediction engine.
- Care/AI output is advisory text; it cannot drive hardware.
- `lib/core/device_timezone.dart` (hand-rolled `menomate/timezone` channel) is the only IANA timezone source; the server owns "today".

## Project structure

Actual layout (`lib/`):

```text
lib/
├── main.dart                  # Supabase init, open Drift file, ProviderScope, router + sync wiring
├── core/
│   ├── api_client.dart        # Dio + AuthInterceptor (Supabase JWT Bearer)
│   ├── device_timezone.dart   # IANA zone via native channel (no plugin)
│   ├── env.dart               # Injected config (SUPABASE_URL/ANON_KEY/API_BASE_URL dart-defines) + release-safe fallbacks
│   ├── format.dart            # Day-count display helper
│   ├── router.dart            # GoRouter: /splash /login /onboarding /home /logger + tab index
│   └── theme.dart             # MenoMateTheme: sakura (light) + starry-night (dark), semantic tokens
├── content/insight_library.dart  # Daily Insight deterministic pair library
├── data/
│   ├── app_database.dart      # Drift schema v2 + migration + date-only helpers (toIsoDate/parseIsoDate)
│   ├── sync_policy.dart       # DataState (Fresh/Cached/PendingSync/…) + typed ApiError
│   └── repositories/          # cycle_repository, daily_log_repository, profile_repository
├── models/                    # cycle, daily_log, profile, summary, care, device, therapy, onboarding
├── providers/                 # auth, cycle (refresh/sync/sign-out), data_providers, profile, theme
├── screens/                   # auth, splash, onboarding, symptom_logger, home_screen,
│   └── tabs/                  # home, assistant (Care), history, settings
├── services/                  # api_service (REST), ble_service (scan + stubbed commands)
├── widgets/                   # cycle ring + phase card, insight card, tracker button,
│                              # logger/telemetry cards, banners, atmosphere painter
├── android/ios                # Native shells; timezone channel in MainActivity.kt + AppDelegate.swift
└── test/                      # Unit + widget tests + offline_fake_api.dart
```

## Current features

**Implemented:** onboarding (atomic profile + first period, sends device timezone), Supabase Auth session, cycle ring + status from server values, period start/end logging with retro-end picker, calendar/history with semantic fills, daily wellness logging, offline-first everything below, cached server predictions, Daily Insight (local library), Care chat (online), Settings (profile, theme, units, device register), sign-out wipe.

**Partial:** BLE — scanning for the `MenoMate` peripheral works (15 s, permission-gated); `sendTherapyCommand` is currently a debug-print stub, no GATT characteristics exist yet, no thermistor streaming, nothing hardware-validated.

**Planned:** push notifications, daily-log personalization, full wearable integration, iOS store release.

## Offline-first behavior

- Reads serve the local row first, then refresh from server when reachable (`Fresh` vs `Cached`/`PendingSync` states).
- Writes apply locally as `pending` immediately, then PATCH/POST upstream; natural keys (`user,log_date`) make retries converge.
- Cached predictions stay displayable until replaced (no TTL expiry).
- Works offline: browse history, log periods/wellness, Daily Insight, cached predictions, retrospective end (device-local dates).
- Needs network: Care chat, first login/onboarding submit, syncing pending rows.
- Sign-out wipes every user-scoped local row + cached prediction.
- Sync is a single best-effort pass on startup/reconnect (`syncAllPending`), oldest-first per store.

## Local database

Drift/SQLite (`menomate.db`, schema v2): `LocalProfiles` (incl. IANA `timezone`), `LocalCycles` (ISO `yyyy-MM-dd` text dates, `localId`/`serverId` reconcile), `LocalDailyLogs` (+ `LocalSymptoms`), `PredictionCache` (7 server fields + `fetchedAt`). Regenerate after table edits:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Date rule (see `toIsoDate`/`parseIsoDate` docs): calendar parts only, device-local, never UTC-shifted.

## API/backend relationship

- Base URL: `Env.apiUrl` (`lib/core/env.dart`). Explicit `--dart-define=API_BASE_URL=…` always wins. Without it, **debug** builds default to `http://127.0.0.1:8000` while **release/profile** builds fall back to the production backend `https://menomate-api.onrender.com` — a release can never silently target localhost.
- Release guard: `main()` refuses to start a release/profile build whose resolved API URL is a development-only endpoint (loopback, emulator alias, or LAN range) and shows a clear misconfiguration screen instead of issuing unusable requests. See `Env.isDevelopmentEndpoint`.
- Auth: Supabase session token injected as `Authorization: Bearer` by the Dio interceptor; 401s surface as auth failures, 404 as no-data, rest as typed errors.
- The app never touches Supabase PostgreSQL directly — only FastAPI routes, only its own user's data.
- Symptom catalog lockstep: the loggable symptom list (`kLoggableSymptoms` in `lib/models/daily_log.dart`) is a hardcoded mirror of the backend catalog (`GET /api/v1/symptoms`). **Any backend change to the symptom catalog must update the mobile list in the same change** — the backend rejects unknown ids with 422.

## Release builds

Production backend: `https://menomate-api.onrender.com`. Supabase URL/anon key always come from injection (never hardcoded, never committed as active credentials).

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://menomate-api.onrender.com \
  --dart-define=SUPABASE_URL=<prod-supabase-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-supabase-anon-key>
# → build/app/outputs/flutter-apk/app-release.apk
```

Release checklist: production defines injected (verify the built config resolves to the production URL, never localhost) • `flutter analyze` clean • `flutter test` green (incl. `test/release_config_test.dart`, also runnable with the production define to verify injection wins) • generated code fresh (`dart run build_runner build --delete-conflicting-outputs`, commit the result).

## BLE

Honest status: peripheral **scan** works; everything past scan is scaffolding. `sendTherapyCommand` logs to console and writes nothing to hardware. There are no GATT service/characteristic UUIDs in the codebase, no temperature stream, no pairing flow beyond the scan UI, and no hardware validation of any kind. Do not document or demo BLE control as working. Web builds explicitly disable BLE paths.

## Daily Insight

Fully local and offline: a small deterministic library (`content/insight_library.dart`) maps cycle context (phase + menstrual day) to one insight + one complementary action slide, with evidence metadata and tiny attribution on select pieces. Manual swipe, no timers, resolve-once per run with safe fallback. A future optional AI layer would consume the `InsightInput` context object and return the same pair shape — it is **not implemented** and must never become required.

## Theme/design system

Semantic roles (both modes, see `core/theme.dart`): **rose = menstrual/logged**, **violet = prediction**, **indigo = interaction/selection**, **sage = wellness**, warm neutrals for canvas/surfaces/borders, deep navy/plum dark foundation, Sakura petals (light) / stars (dark) as quiet atmosphere. Type scale 20/18/16–18/14/12–13/10–11 by role; cards share radius-18, 1px outline, zero-elevation language.

## Timezone/date handling

- Device IANA zone via the native `menomate/timezone` channel; synced to `profiles.timezone` on profile load, sync passes, and onboarding (offline-safe pending row; null never wipes a server value).
- DATE-only fields travel and store as `yyyy-MM-dd` strings; `DateTime.parse` keeps them local-midnight; nothing converts them through UTC.
- "Today", retro-end defaults, and log defaults all use device-local calendar parts offline; the server recomputes authoritatively from the stored zone once online.

## Running locally

Prerequisites: Flutter SDK (developed on 3.47.x; `sdk: ^3.13.2`), Android SDK + platform tools, a device/emulator, and the backend running (see [core README](../MenoMate_core/README.md)).

```bash
flutter pub get
```

Supabase and backend endpoints arrive via `--dart-define` injection (see `.vscode/launch.json` debug configurations and "Release builds" above). URL + **anon public key only** — client-safe; service-role keys must never enter this repo. For a local backend:

```bash
adb reverse tcp:8000 tcp:8000   # physical device over USB
flutter run
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://192.168.1.50:8000
flutter build apk --debug       # → build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release
adb -s <DEVICE_ID> install -r -d -t build/app/outputs/flutter-apk/app-debug.apk
```

## Testing

```bash
flutter analyze
flutter test
```

Suite status (2026-09-13 snapshot): 115 passing — unit (library selection, safety/nutrition wording, timezone plumbing, formatting) + widget (cards, calendar tokens, caching, composition, overflow) + offline sync fakes. Real-device checks still matter for: atmosphere visibility, card proportions, BLE scan, and offline→online transitions.

## Environment/configuration

| Name | Where | Notes |
|---|---|---|
| `Env.supabaseUrl` / `Env.supabaseAnonKey` | `lib/core/env.dart` | Edit per project. Anon key is public-client-safe by design; **never** put service-role or JWT secrets here |
| `API_BASE_URL` | `--dart-define` | Explicit value always wins; debug default `http://127.0.0.1:8000`; release/profile fallback `https://menomate-api.onrender.com`; release guard blocks dev endpoints |

Production notes: release builds need a reachable HTTPS backend URL; the checked-in Supabase project is a development project. `.vscode/launch.json` intentionally keeps working debug launches (dev project defines) — release credentials are injected at build time, never committed.

## Known limitations / future work

- Wearable: scan-only; commands, characteristics, telemetry, and all hardware validation pending.
- Notifications: planned (backend timezone work unblocks scheduling).
- Daily-log personalization: planned (Insight stays library-only until then).
- iOS release packaging: not done.
- Prediction evaluation needs thousands of resolved ledger rows before any model comparison.

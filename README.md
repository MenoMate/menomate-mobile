# MenoMate Mobile

MenoMate Mobile is the cross-platform Flutter client for the MenoMate autonomous menstrual wellness platform. It connects women with real-time cycle intelligence, symptom tracking, guided non-diagnostic care, and Bluetooth Low Energy (BLE) control for the MenoMate thermal and vibrational wearable device.

## Table of Contents

- [Overview](#overview)
- [Architecture and Tech Stack](#architecture-and-tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Command Reference](#command-reference)
  - [Dependencies](#dependencies)
  - [Code Quality and Analysis](#code-quality-and-analysis)
  - [Running the App](#running-the-app)
  - [Building Application Packages](#building-application-packages)
  - [ADB Device Management and Deployment](#adb-device-management-and-deployment)
  - [Automated Testing](#automated-testing)
- [Hardware & BLE Integration](#hardware--ble-integration)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [License](#license)

---

## Overview

The mobile client serves as the primary interface for users to:

- Authenticate and manage their profile securely via Supabase Auth (JWT).
- Complete a structured, atomic onboarding flow capturing baseline cycle length, period duration, and preferences.
- Monitor active menstrual cycle status through an interactive visual cycle ring with phase calculations (Menstrual, Follicular, Ovulation, Luteal) and data-driven predictions.
- Log period start and end events with source-of-truth backend validation that prevents conflicting overlapping entries.
- Record comprehensive daily wellness metrics (pain score 0 to 10, bleeding flow, mood, cervical discharge, notes, and taxonomy-validated symptom lists).
- Converse with MenoMate Care, an empathetic, non-diagnostic AI assistant powered by contextual cycle and symptom telemetry.
- Connect to and command the MenoMate wearable hardware over Bluetooth Low Energy (BLE) for thermal regulation (capped at a strict 44.0 degrees Celsius) and vibrational therapy.

---

## Architecture and Tech Stack

- **Framework**: Flutter 3.x / Dart SDK `^3.13.2`
- **State Management**: Flutter Riverpod (`flutter_riverpod: ^3.4.3`) for reactive, testable state management and scoped provider invalidation.
- **Navigation**: GoRouter (`go_router: ^18.0.1`) for declarative, deep-linkable routing with authentication-aware redirect guards.
- **Authentication**: Supabase Flutter SDK (`supabase_flutter: ^2.17.2`) managing auth state transitions, session persistence, and secure token storage.
- **Network / API Client**: Dio (`dio: ^5.11.1`) with a dedicated `AuthInterceptor` that automatically injects valid Supabase JWT Bearer tokens into outbound requests to `menomate-core`.
- **Bluetooth Hardware Layer**: Flutter Blue Plus (`flutter_blue_plus: ^2.3.12`) for BLE peripheral scanning, connection lifecycle, MTU negotiation, and characteristic read/write/notify operations.
- **Calendar & Visuals**: TableCalendar (`table_calendar: ^3.2.1`) for cycle history visualization; custom Canvas painters for the interactive cycle ring.
- **Design System**: Material 3 theming with custom soft palettes supporting Light, Dark, and System modes.

---

## Project Structure

```text
mobile/
├── android/                   # Android native platform project and Gradle configuration
├── ios/                       # iOS native platform project and CocoaPods configuration
├── lib/
│   ├── core/                  # Core constants, routing, theming, and environment
│   │   ├── env.dart           # Backend API URLs and Supabase public keys
│   │   ├── router.dart        # GoRouter routes and auth redirect logic
│   │   └── theme.dart         # Material 3 light and dark theme definitions
│   ├── models/                # Pydantic-compatible Dart data models (fromJson/toJson)
│   │   ├── cycle.dart         # CycleResponse, CurrentCycleResponse, CycleCreate
│   │   ├── log.dart           # DailyLogResponse, DailyLogCreate, SymptomLogItem
│   │   ├── profile.dart       # ProfileResponse, ProfileUpdate
│   │   ├── summary.dart       # HistorySummaryResponse, CurrentSummaryResponse
│   │   ├── symptom.dart       # SymptomType metadata model
│   │   └── therapy.dart       # TherapyRecommendationResponse, TherapySessionResponse
│   ├── providers/             # Riverpod state providers and invalidation helpers
│   │   ├── auth_provider.dart    # User session, login, signup, logout
│   │   ├── cycle_provider.dart   # Current cycle, cycle history, refreshAllAppData
│   │   ├── device_provider.dart  # Paired BLE hardware and telemetry state
│   │   ├── log_provider.dart     # Daily wellness log retrieval and mutations
│   │   ├── profile_provider.dart # Profile settings and theme preferences
│   │   └── theme_provider.dart   # Active ThemeMode notifier
│   ├── screens/               # Application user interface screens
│   │   ├── auth/              # Sign In, Sign Up, and Password Reset screens
│   │   ├── onboarding/        # Multi-step onboarding setup flow
│   │   ├── tabs/              # Main shell tabs (Home, Care, Calendar, Settings)
│   │   │   ├── home_tab.dart      # Interactive cycle ring, quick actions, insights
│   │   │   ├── care_tab.dart      # MenoMate Care conversational assistant
│   │   │   ├── calendar_tab.dart  # Menstrual cycle calendar and past logs
│   │   │   └── settings_tab.dart  # Account, theme, units, wearable pairing
│   │   └── log/               # Daily wellness and symptom logging screen
│   ├── services/              # External service integrations
│   │   ├── api_service.dart   # REST API client for menomate-core endpoints
│   │   ├── auth_service.dart  # Supabase authentication wrapper
│   │   └── ble_service.dart   # Wearable Bluetooth Low Energy controller
│   ├── widgets/               # Reusable presentation components
│   │   ├── interactive_cycle_ring.dart # Radial menstrual phase progress ring
│   │   ├── period_tracker_button.dart  # State-driven Start / End period action button
│   │   ├── daily_insight_card.dart     # Contextual educational insights card
│   │   └── symptom_logger_card.dart    # Quick-access daily log launcher
│   └── main.dart              # Application entry point, Supabase initialization, ProviderScope
├── test/                      # Unit and widget test suite
├── pubspec.yaml               # Package dependencies, assets, and build configuration
└── README.md                  # Mobile project documentation
```

---

## Prerequisites

Before running the mobile application, ensure the following software is installed on your development workstation:

1. **Flutter SDK**: Version 3.13.2 or newer. Verify by running `flutter --version`.
2. **Android SDK & Build Tools**: Android Studio or command-line tools with API level 33/34 installed.
3. **Android Platform Tools (ADB)**: Ensure `adb` is added to your system `PATH`.
4. **Hardware Device or Emulator**: A physical Android device with Developer Options and USB Debugging enabled, or an Android Virtual Device (AVD).
5. **Backend Server**: The `menomate-core` FastAPI server running locally or accessible via network.

---

## Environment Configuration

The application configuration resides in `lib/core/env.dart`:

```dart
class Env {
  static const String supabaseUrl = 'https://<your-project-id>.supabase.co';
  static const String supabaseAnonKey = '<your-anon-public-key>';
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
```

- **Supabase Keys**: The `supabaseAnonKey` is a client-safe public key intended for mobile consumption.
- **Backend API Base URL**: Defaults to `http://127.0.0.1:8000`. You can override this at runtime or build time using the `--dart-define` flag without modifying source code.

---

## Command Reference

### Dependencies

Fetch all project packages:
```bash
flutter pub get
```

Inspect available package updates:
```bash
flutter pub outdated
```

Upgrade package versions within constraint ranges:
```bash
flutter pub upgrade
```

Clean build artifacts and package caches:
```bash
flutter clean
flutter pub get
```

---

### Code Quality and Analysis

Run the static analyzer to check for errors, warnings, and lint violations:
```bash
flutter analyze
```

Format all Dart source files in the project according to official guidelines:
```bash
dart format .
```

Verify formatting without modifying files (useful for CI/CD pipelines):
```bash
dart format --output=none --set-exit-if-changed .
```

---

### Running the App

#### Step 1: Route Backend Traffic via ADB (Physical Device over USB)

When testing on a physical Android handset connected via USB, configure port forwarding so `http://127.0.0.1:8000` routes directly to the development server on your computer:

```bash
adb reverse tcp:8000 tcp:8000
```

Verify that the rule is registered:
```bash
adb reverse --list
# Expected output: UsbFfs tcp:8000 tcp:8000
```

#### Step 2: Launch the App

Run on the default connected device or emulator:
```bash
flutter run
```

Run on a specific device identified by device ID (from `adb devices`):
```bash
flutter run -d <DEVICE_ID>
```

Run with a custom backend URL (for instance, over local Wi-Fi or a staging server):
```bash
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

Run in release mode for production performance testing:
```bash
flutter run -d <DEVICE_ID> --release
```

---

### Building Application Packages

Build a debug APK:
```bash
flutter build apk --debug
```
Output artifact location:
`build/app/outputs/flutter-apk/app-debug.apk`

Build an optimized release APK:
```bash
flutter build apk --release
```
Output artifact location:
`build/app/outputs/flutter-apk/app-release.apk`

Build an Android App Bundle (AAB) for Google Play distribution:
```bash
flutter build appbundle
```
Output artifact location:
`build/app/outputs/bundle/release/app-release.aab`

---

### ADB Device Management and Deployment

List all attached physical devices and emulators:
```bash
adb devices -l
```

Install the compiled debug APK directly to a target device:
```bash
adb -s <DEVICE_ID> install -r -d -t build/app/outputs/flutter-apk/app-debug.apk
```

Launch the MenoMate application activity directly on the device:
```bash
adb -s <DEVICE_ID> shell monkey -p com.menomate.menomate_mobile -c android.intent.category.LAUNCHER 1
```

Force stop the application:
```bash
adb -s <DEVICE_ID> shell am force-stop com.menomate.menomate_mobile
```

Inspect live application logs and debug prints:
```bash
adb -s <DEVICE_ID> logcat -s flutter
```

Capture a screenshot from the physical device:
```bash
adb -s <DEVICE_ID> exec-out screencap -p > screen.png
```

---

### Automated Testing

Execute all unit and widget tests:
```bash
flutter test
```

Execute tests with detailed verbose output:
```bash
flutter test -v
```

---

## Hardware & BLE Integration

The MenoMate mobile application communicates with the ESP32 wearable hardware over Bluetooth Low Energy:

1. **Permissions**: The application requests runtime permissions via `permission_handler` and `flutter_blue_plus`:
   - Android 12+ (API 31+): `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`.
   - Android 11 and below: `ACCESS_FINE_LOCATION`.
2. **Service Discovery**: The handset scans for peripherals advertising the MenoMate primary therapy service UUID.
3. **Safety Telemetry**: The wearable streams continuous thermistor temperature readings back to the handset.
4. **Actuation Protocol**: The handset transmits deterministic therapy parameters computed by `menomate-core`. Target temperatures are strictly capped at 44.0 degrees Celsius.

---

## Troubleshooting & FAQ

### Device shows "Unable to connect" or Network Errors

1. Verify that the `menomate-core` backend is running:
   ```bash
   curl http://127.0.0.1:8000/health
   # Expected: {"status":"healthy"}
   ```
2. Re-establish ADB port reverse forwarding if the USB cable was disconnected:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
3. Test connectivity directly from the device shell:
   ```bash
   adb shell curl -I http://127.0.0.1:8000/health
   ```

### Device shows "unauthorized" in `adb devices`

1. Unlock the phone screen.
2. Accept the "Allow USB debugging?" dialog prompt.
3. Check "Always allow from this computer" and tap Allow.
4. If the prompt does not appear, disconnect and reconnect the USB cable or restart the ADB server:
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### Cycle Action Button Shows "Log Period Started Today" During an Active Period

The Home screen button derives its state strictly from the active cycle response (`GET /api/v1/cycles/current`):
- If `latest_period_start` is set and `latest_period_end` is null, the button displays `Log Period Ended Today` and executes `POST /api/v1/cycles/current/end`.
- If no period is ongoing, the button displays `Log Period Started Today` and executes `POST /api/v1/cycles`.
- If data appears stale, trigger a pull-to-refresh on the Home tab or invoke `refreshAllAppData(ref)` to invalidate Riverpod caches.

---

## License

Developed as part of the MenoMate autonomous menstrual wellness system. All rights reserved.

# Launcher Icon vs In-App Logo

## Rule

- Home greeting logo beside "Hello, [name]" is FIXED brand identity:
  `MenoMateLogo(variant: standard, size: 34)` in `lib/screens/tabs/home_tab.dart`.
  It never reads `logoVariantProvider`.
- Settings → "App icon (launcher)" previews launcher variants via
  `logoVariantProvider` (`standard` / `framed` / `compact`). It never
  changes the Home header.

## Current native config

- Android: legacy PNGs `android/app/src/main/res/mipmap-*/ic_launcher.png`,
  `android:icon="@mipmap/ic_launcher"`, `android:label="MenoMate"`,
  package `com.menomate.menomate_mobile` (unchanged).
  No `mipmap-anydpi-v26/adaptive-icon.xml`, no `roundIcon`.
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` stock set,
  `CFBundleDisplayName=MenoMate`, `CFBundleName` unchanged.
- In-app brand: `assets/images/menomate_logo_light/dark.png` only.

## Correct implementation (not faked in Home UI)

Dynamic launcher switching is NOT supported by the current
Android/Flutter config. Correct approaches:

1. **Static rebrand (supported now):** Replace `mipmap-*/ic_launcher.png`
   (+ iOS `AppIcon` set) with chosen MenoMate mark, optionally adding
   `mipmap-anydpi-v26/adaptive-icon.xml` + `values/colors.xml` for
   adaptive icons. Rebuild. No Dart change needed.
2. **Runtime switching (requires plugin):** Add
   `flutter_dynamic_icon` (Android) / alternate icons (iOS
   `CFBundleAlternateIcons`), with separate native icon sets per variant,
   permission handling, and fallback when OEMs block it. The existing
   `logoVariantProvider` persistence key (`menomate.logo_variant`) can
   drive the selection, but the actual switch must call platform
   channels — never just swap the Home header.

## Verification

- Change Settings preview → Home header stays classic circle.
- `android:label` reads "MenoMate" in launcher; package remains
  `com.menomate.menomate_mobile`.
- User-facing name: MenoMate everywhere; package ID unchanged.

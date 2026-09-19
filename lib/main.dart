import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/app_database.dart';
import 'providers/cycle_provider.dart';
import 'providers/data_providers.dart';
import 'providers/offline_mode_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Missing runtime configuration (e.g. a production install without
  // --dart-define SUPABASE_URL / SUPABASE_ANON_KEY) must surface as a
  // readable screen, never as a crash before first frame. Auth stays
  // Supabase-backed; this guard only decides whether startup can proceed.
  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    runApp(const _MissingConfigApp());
    return;
  }
  // Release guard: a release/profile build must never silently target a
  // development-only backend (localhost, loopback, or LAN). Fail with a
  // clear screen instead of issuing unusable requests. Debug builds are
  // exempt so local development against a loopback backend keeps working.
  if ((kReleaseMode || kProfileMode) &&
      Env.isDevelopmentEndpoint(Env.apiUrl)) {
    runApp(const _InvalidReleaseConfigApp());
    return;
  }
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
    );
  } catch (_) {
    runApp(const _MissingConfigApp());
    return;
  }

  // Open the local-first database before the UI starts so offline data
  // is available on first frame. path_provider is used only inside here.
  final db = await AppDatabase.openFile('menomate.db');

  runApp(
    // Wrap the entire app in a ProviderScope to enable Riverpod
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MenoMateApp(),
    ),
  );
}

/// Shown when Supabase runtime configuration is missing or invalid.
/// Offline tracking is unavailable before the database opens, so this is a
/// plain explanatory screen: no secrets, no stack trace, no dead button —
/// reinstalling / relaunching with the right build resolves it.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MenoMate',
      theme: MenoMateTheme.sakuraTheme,
      darkTheme: MenoMateTheme.starryNightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: MenoMateTheme.sakuraTheme.colorScheme.error
                        .withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MenoMate couldn\u2019t start',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app is missing its connection settings. '
                    'Please reinstall MenoMate from your usual source '
                    'and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: MenoMateTheme.sakuraTheme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when a release/profile build resolves to a development-only
/// backend endpoint. This is a build/packaging error, never a user error:
/// no request is ever issued, no secret is shown, and reinstalling a
/// correctly built release resolves it.
class _InvalidReleaseConfigApp extends StatelessWidget {
  const _InvalidReleaseConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MenoMate',
      theme: MenoMateTheme.sakuraTheme,
      darkTheme: MenoMateTheme.starryNightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: MenoMateTheme.sakuraTheme.colorScheme.error
                        .withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MenoMate isn\u2019t available right now',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app release was built with an invalid server '
                    'configuration. Please reinstall MenoMate from your '
                    'usual source and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: MenoMateTheme.sakuraTheme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenoMateApp extends ConsumerWidget {
  const MenoMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter instance from our provider
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Activates reconnect/app-start sync passes for the local-first stores.
    ref.watch(connectivitySyncProvider);
    // Clears a stale offline flag once a real session exists.
    ref.watch(offlineFlagJanitorProvider);

    return MaterialApp.router(
      title: 'MenoMate',
      themeMode: themeMode,
      theme: MenoMateTheme.sakuraTheme,
      darkTheme: MenoMateTheme.starryNightTheme,
      routerConfig: router,
    );
  }
}

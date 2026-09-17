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

  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
  );

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

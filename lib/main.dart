import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
  );

  runApp(
    // Wrap the entire app in a ProviderScope to enable Riverpod
    const ProviderScope(
      child: MenoMateApp(),
    ),
  );
}

class MenoMateApp extends ConsumerWidget {
  const MenoMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter instance from our provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MenoMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE17F93)), // A soft rose
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sync_policy.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/symptom_logger_screen.dart';

/// Listenable that triggers GoRouter redirects without destroying the router instance.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
    _ref.listen<AsyncValue<DataState<Profile?>>>(
      profileProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provider that exposes a stable GoRouter instance.
/// It uses [RouterNotifier] as a refreshListenable to re-evaluate [redirect]
/// without tearing down navigation state or rebuilding active screens.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final profileAsync = ref.read(profileProvider);

      final user = authState.value;
      final isAuthLoading = authState.isLoading;

      final location = state.uri.toString();
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isOnboarding = location == '/onboarding';

      // 1. Initializing auth session from Supabase: stay on splash
      if (isAuthLoading) {
        return isSplash ? null : '/splash';
      }

      // 2. Unauthenticated: redirect to login
      if (user == null) {
        return isLogin ? null : '/login';
      }

      // 3. Authenticated: check profile loading and onboarding status
      // 3a. Profile is currently loading: keep user on splash until status is known
      if (profileAsync.isLoading) {
        if (isSplash) return null;
        if (isLogin) return '/splash';
        return null; // Do not interrupt if user is already on home or onboarding
      }

      // 3b. Profile fetch encountered a network or server error
      // CRITICAL: A network/backend error must NOT be interpreted as "needs onboarding"
      if (profileAsync.hasError) {
        if (isSplash) return null; // SplashScreen renders the error & Retry button
        if (isLogin) return '/splash';
        return null;
      }

      // 3c. Profile fetched successfully: check onboarding completion.
      // The value is a DataState: cached/pending/conflict rows still carry
      // a usable profile. Unavailable (no local data + unreachable backend)
      // keeps the user on splash EXACTLY like an error — it must never read
      // as "needs onboarding".
      final dataState = profileAsync.value;
      if (dataState is Unavailable<Profile?>) {
        if (isSplash) return null;
        if (isLogin) return '/splash';
        return null;
      }
      final profile = dataState?.dataOrNull;
      final bool isOnboarded = profile != null &&
          profile.name != null &&
          profile.name!.trim().isNotEmpty;

      if (!isOnboarded) {
        // User needs onboarding
        return isOnboarding ? null : '/onboarding';
      }

      // 3d. User is fully onboarded: redirect away from splash, login, or onboarding to home
      if (isSplash || isLogin || isOnboarding) {
        return '/home';
      }

      // Otherwise allow current route (e.g. /home, /logger)
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/logger',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'];
          final valid =
              date != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
          return SymptomLoggerScreen(initialDate: valid ? date : null);
        },
      ),
    ],
  );
});

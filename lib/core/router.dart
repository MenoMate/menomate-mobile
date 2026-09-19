import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sync_policy.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/onboarding_status_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/aging_context_screen.dart';
import '../screens/calendar_day_detail_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/fertility_log_screen.dart';
import '../screens/health_conditions_screen.dart';
import '../screens/health_context_screen.dart';
import '../screens/health_intro_screen.dart';
import '../screens/health_medications_screen.dart';
import '../screens/health_notes_screen.dart';
import '../screens/health_reproductive_screen.dart';
import '../screens/home_screen.dart';
import '../screens/log_hub_screen.dart';
import '../screens/pregnancy_mode_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/symptom_logger_screen.dart';
import '../screens/tabs/history_tab.dart';
import '../screens/welcome_screen.dart';

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
    _ref.listen<AsyncValue<bool>>(
      offlineModeProvider,
      (_, _) => notifyListeners(),
    );
    _ref.listen<AsyncValue<bool>>(
      onboardingStatusProvider,
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
      final offlineAsync = ref.read(offlineModeProvider);
      final onboardingCompleted =
          ref.read(onboardingStatusProvider).value ?? false;

      final user = authState.value;
      final isAuthLoading = authState.isLoading;
      final isOfflineLoading = offlineAsync.isLoading;

      final location = state.uri.toString();
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isWelcome = location == '/welcome';
      final isOnboarding = location == '/onboarding';

      // 1. Still resolving the Supabase session or the stored path choice:
      // stay on splash. Neither "no session yet" nor "no choice yet" may
      // read as logged-out or offline.
      if (isAuthLoading || isOfflineLoading) {
        return isSplash ? null : '/splash';
      }

      // 2. Authenticated: existing cloud flow. Supabase Auth stays
      // authoritative; an authenticated user is never in offline mode.
      if (user != null) {
        // 2a. Profile is currently loading: keep user on splash until status is known
        if (profileAsync.isLoading) {
          if (isSplash) return null;
          if (isLogin || isWelcome) return '/splash';
          return null; // Do not interrupt if user is already on home or onboarding
        }

        // 2b. Profile fetch encountered a network or server error
        // CRITICAL: A network/backend error must NOT be interpreted as "needs onboarding"
        if (profileAsync.hasError) {
          if (isSplash) {
            return null; // SplashScreen renders the error & Retry button
          }
          if (isLogin || isWelcome) return '/splash';
          return null;
        }

        // 2c. Profile fetched successfully: check onboarding completion.
        // The value is a DataState: cached/pending/conflict rows still carry
        // a usable profile. Unavailable (no local data + unreachable backend)
        // keeps the user on splash EXACTLY like an error — it must never read
        // as "needs onboarding".
        final dataState = profileAsync.value;
        if (dataState is Unavailable<Profile?>) {
          if (isSplash) return null;
          if (isLogin || isWelcome) return '/splash';
          return null;
        }
        final profile = dataState?.dataOrNull;
        // Canonical gate: non-empty name OR explicit local completion flag.
        // The flag protects existing users from transient empty-name
        // payloads; the name covers fresh installs signing into an
        // existing account where the flag was never set on this device.
        final bool isOnboarded = isProfileOnboarded(
          profile,
          onboardingCompleted,
        );

        if (!isOnboarded) {
          // User needs onboarding
          return isOnboarding ? null : '/onboarding';
        }

        // 2d. User is fully onboarded: redirect away from entry routes to home
        if (isSplash || isLogin || isOnboarding || isWelcome) {
          return '/home';
        }

        // Otherwise allow current route (e.g. /home, /logger)
        return null;
      }

      final offline = offlineAsync.value ?? false;
      if (!offline) {
        // 3. No session and no offline choice: path choice (+ direct login
        // entry for returning users and deep links).
        if (isWelcome || isLogin) return null;
        return '/welcome';
      }

      // 4. Offline/local user: same profile-gated flow as auth, served from
      // local rows only. /login stays reachable voluntarily (the Settings
      // sign-in path) but is never forced.
      if (profileAsync.isLoading) {
        if (isSplash) return null;
        if (isLogin || isWelcome || isOnboarding) return '/splash';
        return null;
      }

      if (profileAsync.hasError) {
        if (isSplash) return null;
        if (isLogin || isWelcome) return '/splash';
        return null;
      }

      final offlineState = profileAsync.value;
      if (offlineState is Unavailable<Profile?>) {
        // Unreachable for local-only reads; kept as a fail-closed guard.
        if (isSplash) return null;
        if (isLogin || isWelcome) return '/splash';
        return null;
      }
      final offlineProfile = offlineState?.dataOrNull;
      final bool offlineOnboarded = isProfileOnboarded(
        offlineProfile,
        onboardingCompleted,
      );

      if (!offlineOnboarded) {
        // /login stays reachable voluntarily (sign in instead of
        // onboarding offline); every other route still funnels here.
        if (isOnboarding || isLogin) return null;
        return '/onboarding';
      }

      // /login stays reachable voluntarily (the Settings sign-in path):
      // bouncing it back to /home makes the button look dead. Entry and
      // setup routes still funnel to /home once tracking is set up.
      if (isSplash || isOnboarding || isWelcome) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      // Calendar hierarchy: Year → Month → Day Detail. /calendar is the
      // combined month+year experience (tab); /calendar/day is the
      // dedicated day detail; /history is kept as a legacy alias that
      // renders the same calendar so old deep links and Care actions
      // keep working.
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/calendar/day',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'];
          final valid =
              date != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
          return CalendarDayDetailScreen(isoDate: valid ? date : '');
        },
      ),
      GoRoute(path: '/log', builder: (context, state) => const LogHubScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryTab(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/health',
        builder: (context, state) => const HealthContextScreen(),
      ),
      GoRoute(
        path: '/profile/health/conditions',
        builder: (context, state) => const HealthConditionsScreen(),
      ),
      GoRoute(
        path: '/profile/health/medications',
        builder: (context, state) => const HealthMedicationsScreen(),
      ),
      GoRoute(
        path: '/profile/health/reproductive',
        builder: (context, state) => const HealthReproductiveScreen(),
      ),
      GoRoute(
        path: '/profile/health/pregnancy-mode',
        builder: (context, state) => const PregnancyModeScreen(),
      ),
      GoRoute(
        path: '/profile/health/aging',
        builder: (context, state) => const AgingContextScreen(),
      ),
      GoRoute(
        path: '/profile/health/notes',
        builder: (context, state) => const HealthNotesScreen(),
      ),
      GoRoute(
        path: '/health-intro',
        builder: (context, state) => const HealthIntroScreen(),
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
      GoRoute(
        path: '/fertility-log',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'];
          final valid =
              date != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
          return FertilityLogScreen(initialDate: valid ? date : null);
        },
      ),
    ],
  );
});

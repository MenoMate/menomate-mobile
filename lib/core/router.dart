import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

import '../screens/symptom_logger_screen.dart';

/// Provider that exposes the GoRouter instance. 
/// It watches the [authStateProvider] and [profileProvider] to automatically redirect users
/// based on their authentication status and onboarding completion.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoadingAuth = authState.isLoading;
      final user = authState.value;

      final isSplash = state.uri.toString() == '/splash';
      final isLoggingIn = state.uri.toString() == '/login';
      final isOnboarding = state.uri.toString() == '/onboarding';
      final isLogger = state.uri.toString() == '/logger';

      // If we are still loading the initial auth state from Supabase, stay on splash
      if (isLoadingAuth) {
        return isSplash ? null : '/splash';
      }

      // If there is no user and we aren't already on the login screen, redirect to login
      if (user == null && !isLoggingIn) {
        return '/login';
      }
      
      // If the user is authenticated, check their profile status
      if (user != null) {
        // Wait for profile to load before making routing decisions
        if (profileAsync.isLoading) {
          return isSplash ? null : '/splash';
        }

        final profile = profileAsync.value;
        // If profile fetch failed or name is missing, they need onboarding
        final needsOnboarding = profile == null || profile.name == null || profile.name!.isEmpty;

        if (needsOnboarding && !isOnboarding) {
          return '/onboarding';
        }

        // If they are onboarded, don't let them on splash, login, or onboarding screens
        if (!needsOnboarding && (isLoggingIn || isSplash || isOnboarding)) {
          return '/home';
        }
      }

      // Otherwise, no redirect needed
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
        builder: (context, state) => const SymptomLoggerScreen(),
      ),
    ],
  );
});

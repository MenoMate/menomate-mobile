import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:menomate_mobile/core/router.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/auth_provider.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/offline_mode_provider.dart';
import 'package:menomate_mobile/providers/onboarding_status_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';

/// Phase 2 navigation foundation contract.
///
/// Drives the REAL router ([routerProvider] + [routerNotifierProvider])
/// with the auth/offline/profile boundaries overridden — the same level
/// the existing router tests use. No Supabase network, no fake sessions:
/// authenticated cases use the SDK's own [User] model.
///
/// Covers: welcome-first (never login-first), login reachability, local
/// onboarding without login, completion gating, existing users never
/// re-trapped, and post-logout entry.
class _FakeOffline extends OfflineModeNotifier {
  final bool flag;
  _FakeOffline(this.flag);

  @override
  Future<bool> build() async => flag;
}

class _FixedProfile extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfile(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

class _FixedOnboarding extends OnboardingStatusNotifier {
  final bool flag;
  _FixedOnboarding(this.flag);

  @override
  Future<bool> build() async => flag;
}

User _fakeUser() => User(
      id: 'auth-user-1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

Profile _profile(String userId, {String? name = 'Ama'}) => Profile(
      userId: userId,
      name: name,
      usualCycleDays: 28,
      usualPeriodDays: 5,
      theme: 'light',
      units: 'metric',
      timezone: 'Asia/Kolkata',
    );

void main() {
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    User? user,
    required bool offline,
    required DataState<Profile?> profile,
    bool completedFlag = false,
  }) async {
    late GoRouter router;
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
          offlineModeProvider.overrideWith(() => _FakeOffline(offline)),
          profileProvider.overrideWith(() => _FixedProfile(profile)),
          onboardingStatusProvider
              .overrideWith(() => _FixedOnboarding(completedFlag)),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    return router;
  }

  group('welcome-first entry (never login-first)', () {
    testWidgets('undecided user lands on welcome, not login', (tester) async {
      final router = await pumpRouter(
        tester,
        offline: false,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/welcome');
      expect(find.textContaining('Your body has a rhythm.'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.textContaining('Log in'), findsOneWidget);
      expect(router.state.uri.toString(), isNot('/login'));
    });

    testWidgets('login stays reachable from welcome', (tester) async {
      final router = await pumpRouter(
        tester,
        offline: false,
        profile: const NoData<Profile?>(),
      );
      await tester.tap(find.textContaining('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.state.uri.toString(), '/login');
    });
  });

  group('local onboarding without login', () {
    testWidgets('offline user without profile reaches onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/onboarding');
    });

    testWidgets('offline onboarded user reaches home', (tester) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: Fresh<Profile?>(_profile(kOfflineUserId)),
      );
      expect(router.state.uri.toString(), '/home');
    });
  });

  group('authenticated routing', () {
    testWidgets('new authenticated user reaches onboarding', (tester) async {
      final router = await pumpRouter(
        tester,
        user: _fakeUser(),
        offline: false,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/onboarding');
    });

    testWidgets('completed authenticated user reaches home', (tester) async {
      final router = await pumpRouter(
        tester,
        user: _fakeUser(),
        offline: false,
        profile: Fresh<Profile?>(_profile('auth-user-1')),
      );
      expect(router.state.uri.toString(), '/home');
    });
  });

  group('existing users are never re-trapped', () {
    testWidgets('completion flag alone routes offline user home', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: const NoData<Profile?>(),
        completedFlag: true,
      );
      expect(router.state.uri.toString(), '/home');
    });
  });

  group('post-logout entry', () {
    testWidgets('logged-out user returns to welcome', (tester) async {
      // signOutAndClearLocalData leaves: no session, no offline flag,
      // wiped local rows (NoData) and a cleared completion flag.
      final router = await pumpRouter(
        tester,
        offline: false,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/welcome');
    });
  });
}

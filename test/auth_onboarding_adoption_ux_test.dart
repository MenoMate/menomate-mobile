import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/core/router.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/auth_provider.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/offline_mode_provider.dart';
import 'package:menomate_mobile/providers/onboarding_status_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/auth_screen.dart';
import 'package:menomate_mobile/screens/onboarding_screen.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_fake_api.dart';

User _makeUser({
  String id = 'auth-user-1',
  String email = 'user@example.com',
  List<UserIdentity>? identities,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {'name': 'Maya'},
    aud: 'authenticated',
    createdAt: '2026-11-24T00:00:00Z',
    email: email,
    identities: identities,
  );
}

Session _makeSession(User user) {
  return Session(
    accessToken: 'fake-jwt-token',
    tokenType: 'bearer',
    user: user,
  );
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  int signUpCalls = 0;
  int signInCalls = 0;
  Future<AuthResponse> Function({
    String? email,
    required String password,
    Map<String, dynamic>? data,
  })?
  onSignUp;
  Future<AuthResponse> Function({
    String? email,
    required String password,
  })?
  onSignIn;

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();
  Session? _session;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  void emitSignedIn(Session session) {
    _session = session;
    _controller.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    signUpCalls++;
    final res = await onSignUp!(email: email, password: password, data: data);
    if (res.session != null) {
      emitSignedIn(res.session!);
    }
    return res;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    signInCalls++;
    final res = await onSignIn!(email: email, password: password);
    if (res.session != null) {
      emitSignedIn(res.session!);
    }
    return res;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  final _FakeGoTrueClient fakeAuth;
  _FakeSupabaseClient(this.fakeAuth);

  @override
  GoTrueClient get auth => fakeAuth;
}

class _FakeOfflineNotifier extends OfflineModeNotifier {
  final bool initial;
  _FakeOfflineNotifier(this.initial);

  @override
  Future<bool> build() async => initial;
}

class _ControllableProfileNotifier extends ProfileNotifier {
  int reloadCalls = 0;
  Completer<DataState<Profile?>>? pendingLoad;
  DataState<Profile?> current;

  _ControllableProfileNotifier(this.current);

  @override
  Future<DataState<Profile?>> build() async {
    if (pendingLoad != null) {
      return pendingLoad!.future;
    }
    return current;
  }
}

class _FixedOnboardingStatusNotifier extends OnboardingStatusNotifier {
  final bool completed;
  _FixedOnboardingStatusNotifier(this.completed);

  @override
  Future<bool> build() async => completed;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth routing & mode defaults', () {
    testWidgets('/login defaults to Sign In mode', (tester) async {
      final fakeAuth = _FakeGoTrueClient();
      addTearDown(fakeAuth.dispose);
      final fakeClient = _FakeSupabaseClient(fakeAuth);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(fakeClient),
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            offlineModeProvider.overrideWith(() => _FakeOfflineNotifier(false)),
            onboardingStatusProvider.overrideWith(
              () => _FixedOnboardingStatusNotifier(false),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(routerConfig: ref.watch(routerProvider));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text('What should we call you?'), findsNothing);
    });

    testWidgets('/login?mode=signup opens Create Account mode', (tester) async {
      final fakeAuth = _FakeGoTrueClient();
      addTearDown(fakeAuth.dispose);
      final fakeClient = _FakeSupabaseClient(fakeAuth);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(fakeClient),
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            offlineModeProvider.overrideWith(() => _FakeOfflineNotifier(false)),
            onboardingStatusProvider.overrideWith(
              () => _FixedOnboardingStatusNotifier(false),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(routerConfig: ref.watch(routerProvider));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/login?mode=signup');
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Create Account'),
        findsOneWidget,
      );
      expect(find.text('What should we call you?'), findsOneWidget);
    });
  });

  group('AuthScreen signup & sign-in UX', () {
    testWidgets('successful signup with session triggers auth-state navigation',
        (tester) async {
      final fakeAuth = _FakeGoTrueClient();
      addTearDown(fakeAuth.dispose);
      final user = _makeUser(id: 'new-user-1');
      final session = _makeSession(user);
      fakeAuth.onSignUp = ({email, required password, data}) async {
        return AuthResponse(session: session, user: user);
      };
      final fakeClient = _FakeSupabaseClient(fakeAuth);

      final db = AppDatabase.memory();
      addTearDown(db.close);
      final fakeApi = FakeApiService()
        ..serverProfile = Profile(userId: 'new-user-1', name: 'Maya');
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(fakeClient),
            appDatabaseProvider.overrideWithValue(db),
            apiServiceProvider.overrideWithValue(fakeApi),
            offlineModeProvider.overrideWith(() => _FakeOfflineNotifier(false)),
            onboardingStatusProvider.overrideWith(
              () => _FixedOnboardingStatusNotifier(true),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(routerConfig: ref.watch(routerProvider));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/login?mode=signup');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Maya',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email Address'),
        'maya@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'secret123',
      );

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(fakeAuth.signUpCalls, 1);
      expect(fakeAuth.signInCalls, 0);
      // Auth-state change routed through /splash -> /home
      expect(find.byType(HomeTab), findsOneWidget);
    });

    testWidgets(
      'duplicate account error switches to Sign In, keeps email, clears passwords',
      (tester) async {
        final fakeAuth = _FakeGoTrueClient();
        addTearDown(fakeAuth.dispose);
        fakeAuth.onSignUp = ({email, required password, data}) async {
          throw const AuthException(
            'User already registered',
            statusCode: '422',
            code: 'user_already_exists',
          );
        };
        final fakeClient = _FakeSupabaseClient(fakeAuth);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(fakeClient),
              isOfflineTrackingProvider.overrideWithValue(false),
            ],
            child: const MaterialApp(home: AuthScreen(initialLoginMode: false)),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'What should we call you?'),
          'Maya',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Email Address'),
          'maya@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'secret123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Confirm Password'),
          'secret123',
        );

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Create Account'),
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        // Switched to Sign In mode
        expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
        expect(find.textContaining('already exists'), findsOneWidget);
        // Email retained, password cleared
        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email Address'),
        );
        final passwordField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Password'),
        );
        expect(emailField.controller?.text, 'maya@example.com');
        expect(passwordField.controller?.text, isEmpty);
      },
    );

    testWidgets(
      'unexpected null-session signup switches to Sign In without claiming email confirmation',
      (tester) async {
        final fakeAuth = _FakeGoTrueClient();
        addTearDown(fakeAuth.dispose);
        fakeAuth.onSignUp = ({email, required password, data}) async {
          return AuthResponse(
            session: null,
            user: _makeUser(identities: const []),
          );
        };
        final fakeClient = _FakeSupabaseClient(fakeAuth);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(fakeClient),
              isOfflineTrackingProvider.overrideWithValue(false),
            ],
            child: const MaterialApp(home: AuthScreen(initialLoginMode: false)),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'What should we call you?'),
          'Maya',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Email Address'),
          'maya@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'secret123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Confirm Password'),
          'secret123',
        );

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Create Account'),
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
        expect(
          find.textContaining('couldn\u2019t start a session'),
          findsOneWidget,
        );
        expect(find.textContaining('confirmation link'), findsNothing);
        expect(find.textContaining('Resend'), findsNothing);
        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email Address'),
        );
        expect(emailField.controller?.text, 'maya@example.com');
      },
    );

    testWidgets('invalid credentials and network errors retain email', (
      tester,
    ) async {
      final fakeAuth = _FakeGoTrueClient();
      addTearDown(fakeAuth.dispose);
      fakeAuth.onSignIn = ({email, required password}) async {
        throw const AuthException('Invalid login credentials', statusCode: '400');
      };
      final fakeClient = _FakeSupabaseClient(fakeAuth);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(fakeClient),
            isOfflineTrackingProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email Address'),
        'maya@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrongpass',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('don\u2019t match'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Email Address'))
            .controller
            ?.text,
        'maya@example.com',
      );

      // Now simulate network failure
      fakeAuth.onSignIn = ({email, required password}) async {
        throw const SocketException('Failed host lookup');
      };
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Check your connection'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Email Address'))
            .controller
            ?.text,
        'maya@example.com',
      );
    });

    testWidgets(
      'multiple keyboard submissions cannot trigger concurrent requests and Sign In shows loading feedback',
      (tester) async {
        final fakeAuth = _FakeGoTrueClient();
        addTearDown(fakeAuth.dispose);
        final completer = Completer<AuthResponse>();
        fakeAuth.onSignIn = ({email, required password}) => completer.future;
        final fakeClient = _FakeSupabaseClient(fakeAuth);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(fakeClient),
              isOfflineTrackingProvider.overrideWithValue(false),
            ],
            child: const MaterialApp(home: AuthScreen()),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Email Address'),
          'maya@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'secret123',
        );

        // Trigger via keyboard Done multiple times rapidly
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(fakeAuth.signInCalls, 1);
        expect(find.text('Signing in...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(
          AuthResponse(session: null, user: null),
        );
        await tester.pumpAndSettle();
      },
    );
  });

  group('Onboarding completion UX', () {
    testWidgets(
      'Go to my Home shows loading state, prevents repeat taps, and surfaces retry on failure',
      (tester) async {
        final fakeDb = AppDatabase.memory();
        addTearDown(fakeDb.close);
        final profileCompleter = Completer<DataState<Profile?>>();
        final profileNotifier = _ControllableProfileNotifier(
          Fresh<Profile?>(Profile(userId: 'u1', name: 'Maya')),
        );
        // After refreshAllAppData invalidates profileProvider, build() awaits pendingLoad.
        profileNotifier.pendingLoad = profileCompleter;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(fakeDb),
            apiServiceProvider.overrideWithValue(
              FakeApiService()
                ..serverProfile = Profile(userId: 'u1', name: 'Maya'),
            ),
            authUserIdProvider.overrideWithValue('u1'),
            currentUserIdProvider.overrideWithValue('u1'),
            isOfflineTrackingProvider.overrideWithValue(false),
            onboardingStatusProvider.overrideWith(
              () => _FixedOnboardingStatusNotifier(true),
            ),
            profileProvider.overrideWith(() => profileNotifier),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Name
      await tester.enterText(find.byType(TextField).first, 'Maya');
      await tester.tap(find.text('Continue').last);
      await tester.pumpAndSettle();
      // Step 1: Interests (Skip)
      await tester.tap(find.text('Skip').first);
      await tester.pumpAndSettle();
      // Step 2: Cycle (set start date + Ongoing, then Continue)
      await tester.tap(
        find.text('I don\u2019t remember — use today (approximate)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ongoing'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue').last);
      await tester.tap(find.text('Continue').last);
      await tester.pumpAndSettle();
      // Skip tracking + personal + basics
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Skip').first);
        await tester.pumpAndSettle();
      }
      // Step 6: Ready -> Enter MenoMate
      await tester.ensureVisible(find.text('Enter MenoMate'));
      await tester.tap(find.text('Enter MenoMate'));
      await tester.pumpAndSettle();

      // Now on _sDone: Go to my Home
      expect(find.text('Go to my Home'), findsOneWidget);
      await tester.tap(find.text('Go to my Home'));
      await tester.pump();

      // Loading state shown and repeat tap is ignored
      expect(find.text('Opening Home...'), findsOneWidget);
      await tester.tap(find.text('Opening Home...'));
      await tester.pump();

      // Complete with Unavailable -> surfaces retry option
      profileCompleter.complete(const Unavailable('Network error'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.textContaining('Couldn\u2019t verify your profile'),
        findsOneWidget,
      );
      },
    );
  });

  group('Guest-data adoption on HomeTab', () {
    Future<void> seedGuest(AppDatabase db) async {
      await db
          .into(db.localCycles)
          .insert(
            LocalCyclesCompanion.insert(
              localId: 'guest-cycle-1',
              userId: kOfflineUserId,
              periodStart: '2026-10-01',
              syncState: const Value(SyncState.pending),
            ),
          );
      await db
          .into(db.localDailyLogs)
          .insert(
            LocalDailyLogsCompanion.insert(
              userId: kOfflineUserId,
              logDate: '2026-10-02',
              pain: const Value(3),
              syncState: const Value(SyncState.pending),
            ),
          );
    }

    testWidgets('shows nothing when no adoptable guest records exist', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final fakeApi = FakeApiService()
        ..serverProfile = Profile(userId: 'auth-1', name: 'Maya');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            apiServiceProvider.overrideWithValue(fakeApi),
            authUserIdProvider.overrideWithValue('auth-1'),
            currentUserIdProvider.overrideWithValue('auth-1'),
            isOfflineTrackingProvider.overrideWithValue(false),
            profileProvider.overrideWith(
              () => _ControllableProfileNotifier(
                Fresh<Profile?>(Profile(userId: 'auth-1', name: 'Maya')),
              ),
            ),
          ],
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Local records saved on this device'), findsNothing);
      expect(find.text('Review and import'), findsNothing);
    });

    testWidgets(
      'appears when guest records exist, Not now preserves records and suppresses repeat prompt',
      (tester) async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        await seedGuest(db);
        final fakeApi = FakeApiService()
          ..serverProfile = Profile(userId: 'auth-1', name: 'Maya');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              apiServiceProvider.overrideWithValue(fakeApi),
              authUserIdProvider.overrideWithValue('auth-1'),
              currentUserIdProvider.overrideWithValue('auth-1'),
              isOfflineTrackingProvider.overrideWithValue(false),
              profileProvider.overrideWith(
                () => _ControllableProfileNotifier(
                  Fresh<Profile?>(Profile(userId: 'auth-1', name: 'Maya')),
                ),
              ),
            ],
            child: const MaterialApp(home: HomeTab()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Local records saved on this device'), findsOneWidget);
        expect(find.text('Review and import'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);

        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        expect(find.text('Local records saved on this device'), findsNothing);
        // Guest records preserved under kOfflineUserId
        final counts = await db.offlineAdoptableCounts();
        expect(counts.cycles, 1);
        expect(counts.logs, 1);
      },
    );

    testWidgets(
      'Review and import adopts records under authenticated user and hides prompt',
      (tester) async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        await seedGuest(db);
        final fakeApi = FakeApiService()
          ..serverProfile = Profile(userId: 'auth-1', name: 'Maya');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              apiServiceProvider.overrideWithValue(fakeApi),
              authUserIdProvider.overrideWithValue('auth-1'),
              currentUserIdProvider.overrideWithValue('auth-1'),
              isOfflineTrackingProvider.overrideWithValue(false),
              profileProvider.overrideWith(
                () => _ControllableProfileNotifier(
                  Fresh<Profile?>(Profile(userId: 'auth-1', name: 'Maya')),
                ),
              ),
            ],
            child: const MaterialApp(home: HomeTab()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Review and import'));
        await tester.pumpAndSettle();

        // Prompt disappears and guest rows moved to auth-1
        expect(find.text('Local records saved on this device'), findsNothing);
        final remainingGuest = await db.offlineAdoptableCounts();
        expect(remainingGuest.cycles, 0);
        expect(remainingGuest.logs, 0);

        final adoptedCycles = await (db.select(db.localCycles)
              ..where((t) => t.userId.equals('auth-1')))
            .get();
        expect(adoptedCycles.length, 1);
      },
    );

    testWidgets('failed adoption preserves records for retry', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seedGuest(db);
      final fakeApi = FakeApiService()
        ..serverProfile = Profile(userId: 'auth-1', name: 'Maya')
        ..offline = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            apiServiceProvider.overrideWithValue(fakeApi),
            authUserIdProvider.overrideWithValue('auth-1'),
            currentUserIdProvider.overrideWithValue('auth-1'),
            isOfflineTrackingProvider.overrideWithValue(false),
            profileProvider.overrideWith(
              () => _ControllableProfileNotifier(
                Fresh<Profile?>(Profile(userId: 'auth-1', name: 'Maya')),
              ),
            ),
          ],
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review and import'));
      await tester.pumpAndSettle();

      // Local rows were adopted to auth-1 and preserved with pending sync for retry
      final adoptedCycles = await (db.select(db.localCycles)
            ..where((t) => t.userId.equals('auth-1')))
          .get();
      expect(adoptedCycles.length, 1);
      expect(adoptedCycles.first.syncState, SyncState.pending);
    });
  });
}

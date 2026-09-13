import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/profile_repository.dart';
import 'package:menomate_mobile/models/onboarding.dart';
import 'package:menomate_mobile/models/profile.dart';

import 'offline_fake_api.dart';

/// Batch 2D-1 (mobile): the canonical IANA timezone flows device -> local
/// row -> server profile, and never wipes a value stored by another device.
/// The native plugin is unavailable in unit tests, so device lookup is
/// expected to degrade to a silent no-op (never a throw, never UTC).
void main() {
  const userId = 'user-a';

  ProfileRepository repo(AppDatabase db, FakeApiService api) =>
      ProfileRepository(db, api);

  group('model plumbing', () {
    test('Profile json round-trips timezone', () {
      final p = Profile(userId: 'u', timezone: 'Asia/Kolkata');
      expect(Profile.fromJson(p.toJson()).timezone, 'Asia/Kolkata');

      final legacy = Profile(userId: 'u');
      expect(legacy.toJson()['timezone'], isNull);
      expect(Profile.fromJson(const {'user_id': 'u'}).timezone, isNull);
    });

    test('OnboardingRequest carries timezone', () {
      final req = OnboardingRequest(
        name: 'n',
        lastPeriodStart: '2026-09-01',
        timezone: 'America/New_York',
      );
      expect(req.toJson()['timezone'], 'America/New_York');

      final noTz = OnboardingRequest(name: 'n', lastPeriodStart: '2026-09-01');
      expect(noTz.toJson()['timezone'], isNull);
    });
  });

  group('local row + sync', () {
    test('offline timezone save stages pending without network', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final r = repo(db, api);

      await r.saveProfile(userId, {'timezone': 'Asia/Kolkata'});

      final row = await (db.select(db.localProfiles)
            ..where((t) => t.userId.equals(userId)))
          .getSingle();
      expect(row.timezone, 'Asia/Kolkata');
      expect(api.patchProfileCalls, 0);
    });

    test('syncPending sends a set timezone upstream', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final r = repo(db, api);

      await r.saveProfile(userId, {'timezone': 'Asia/Kolkata'});
      api.offline = false;
      await r.syncPending(userId);

      expect(api.serverProfile.timezone, 'Asia/Kolkata');
      final row = await (db.select(db.localProfiles)
            ..where((t) => t.userId.equals(userId)))
          .getSingle();
      expect(row.timezone, 'Asia/Kolkata');
    });

    test('syncPending never clears a server timezone with null', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService()
        ..offline = true
        ..serverProfile = Profile(userId: 'user-a', timezone: 'Europe/Berlin');
      final r = repo(db, api);

      // Local pending row without a zone (e.g. legacy row, name edit).
      await r.saveProfile(userId, {'name': 'A'});
      api.offline = false;
      await r.syncPending(userId);

      // Server value from the other device survives; local adopts it.
      expect(api.serverProfile.timezone, 'Europe/Berlin');
      final row = await (db.select(db.localProfiles)
            ..where((t) => t.userId.equals(userId)))
          .getSingle();
      expect(row.timezone, 'Europe/Berlin');
    });
  });

  group('device lookup resilience', () {
    test('refresh is a silent no-op when the platform is unreachable',
        () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final r = repo(db, FakeApiService());

      // No native plugin in unit tests: must complete, create nothing.
      await r.refreshDeviceTimezone(userId);

      final rows = await db.select(db.localProfiles).get();
      expect(rows, isEmpty);
    });
  });
}

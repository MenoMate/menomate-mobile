import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import 'data_providers.dart';

/// In-memory UI theme state with local persistence. The theme column of the
/// local profile row is the persistent source; backend sync of the theme
/// rides on the normal profile sync pass (row stays pending until PATCHed).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_hydrate);
    return ThemeMode.light;
  }

  Future<void> _hydrate() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final db = ref.read(appDatabaseProvider);
      final row = await (db.select(
        db.localProfiles,
      )..where((t) => t.userId.equals(userId))).getSingleOrNull();
      final saved = row?.theme?.toLowerCase();
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Persistence unavailable; in-memory default stands.
    }
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    unawaited(_persist(state == ThemeMode.dark ? 'dark' : 'light'));
  }

  /// Targeted theme write: updates only the theme/sync bookkeeping
  /// columns so display name, usual lengths, units, and timezone are never
  /// clobbered. Falls back to a minimal insert only when no profile row
  /// exists yet for this user.
  Future<void> _persist(String theme) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final db = ref.read(appDatabaseProvider);
      final updated =
          await (db.update(
            db.localProfiles,
          )..where((t) => t.userId.equals(userId))).write(
            LocalProfilesCompanion(
              theme: Value(theme),
              syncState: const Value(SyncState.pending),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (updated == 0) {
        await db
            .into(db.localProfiles)
            .insert(
              LocalProfilesCompanion.insert(
                userId: userId,
                theme: Value(theme),
                syncState: const Value(SyncState.pending),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    } catch (_) {
      // Local persist failed; in-memory state still applies this session.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

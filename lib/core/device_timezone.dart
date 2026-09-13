import 'package:flutter/services.dart';

/// Device IANA timezone identifier (e.g. "Asia/Kolkata") for user-local
/// calendar semantics.
///
/// Served by a tiny hand-rolled platform channel (`menomate/timezone`,
/// implemented in MainActivity.kt / AppDelegate.swift) so no third-party
/// dependency is needed: Android returns `TimeZone.getDefault().id`,
/// iOS returns `TimeZone.current.identifier`.
///
/// The backend stores this single canonical value on the profile and uses
/// it to derive the authoritative user-local "today". We never store a
/// numeric offset (loses DST/history) or an abbreviation (ambiguous).
/// Returns null when the platform cannot provide a name; callers treat
/// null as "unknown, keep existing value and retry next session" — never
/// as UTC, and never as a failure.
const _channel = MethodChannel('menomate/timezone');

Future<String?> deviceTimeZoneId() async {
  try {
    final name = await _channel.invokeMethod<String>('getLocalTimezone');
    if (name == null || name.isEmpty) return null;
    return name;
  } catch (_) {
    return null;
  }
}

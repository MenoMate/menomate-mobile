import 'package:flutter/foundation.dart';

/// Runtime environment configuration (release-hardened).
///
/// Every value arrives via `--dart-define` / environment injection — no
/// secret or endpoint is ever hardcoded as an active credential. The only
/// hardcoded strings are the well-known public production endpoint (used
/// as a release-safe fallback) and the loopback default (debug only).
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Raw injected API base URL. Empty when no `--dart-define=API_BASE_URL`
  /// was passed to the build/run command.
  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Production backend. Release/profile builds fall back to this instead
  /// of localhost so a release can never silently target a dev server.
  static const productionApiUrl = 'https://menomate-api.onrender.com';

  /// Development backend for debug runs without explicit injection.
  /// Debug-only: never used by release/profile builds (see [apiUrl] and
  /// the release guard in `main()`).
  static const debugApiUrl = 'http://127.0.0.1:8000';

  /// Effective base URL. Explicit injection always wins; otherwise
  /// release/profile resolve to production and debug resolves to the
  /// local loopback so day-to-day development keeps working unchanged.
  static String get apiUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    if (kReleaseMode || kProfileMode) return productionApiUrl;
    return debugApiUrl;
  }

  /// True when [url] targets a development-only endpoint (loopback,
  /// link-local test addresses, or LAN/private ranges). Release builds
  /// must never resolve to one of these — `main()` fails clearly instead
  /// of silently issuing unusable requests.
  static bool isDevelopmentEndpoint(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.isEmpty) return true;
    if (host == 'localhost' ||
        host == '::1' ||
        host == '0.0.0.0' ||
        host == '10.0.2.2' ||
        host.endsWith('.local')) {
      return true;
    }
    if (host.startsWith('127.') || host.startsWith('0.')) return true;
    if (host.startsWith('10.') || host.startsWith('192.168.')) return true;
    final oneTwoSeven = RegExp(r'^172\.(1[6-9]|2\d|3[01])\.');
    if (oneTwoSeven.hasMatch(host)) return true;
    return false;
  }
}

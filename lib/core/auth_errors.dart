/// User-facing authentication error mapping (Phase 1).
///
/// Every auth failure that can reach the UI is converted here into a clean,
/// actionable message. Raw socket errors, HTTP internals, Supabase
/// exception details, URLs, and secrets must never be shown — callers
/// display ONLY the returned string.
///
/// Pure functions (no widgets, no Supabase calls) so the full matrix is
/// unit-tested in `test/auth_errors_test.dart`.
library;

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// True for transport-level failures (no route to the auth service), as
/// opposed to credential/account problems. Covers dart:io failures and the
/// `package:http` [ClientException] text that wraps the same OS failures.
bool isAuthNetworkError(Object e) {
  if (e is SocketException || e is TimeoutException || e is HttpException) {
    return true;
  }
  final message = e.toString();
  return message.contains('SocketException') ||
      message.contains('ClientException') ||
      message.contains('Failed host lookup') ||
      message.contains('Connection refused') ||
      message.contains('Connection timed out') ||
      message.contains('Connection reset') ||
      message.contains('Network is unreachable') ||
      message.contains('timed out');
}

/// Clean message for a signup/sign-in failure. Never null.
String friendlyAuthErrorMessage(Object e) {
  if (isAuthNetworkError(e)) {
    return 'Couldn\u2019t reach the sign-in service. Check your connection and try again.';
  }
  if (e is AuthException) {
    return _supabaseMessage(e);
  }
  return 'Something went wrong. Please try again.';
}

String _supabaseMessage(AuthException e) {
  final code = (e.code ?? '').toLowerCase();
  final message = e.message.toLowerCase();
  final status = e.statusCode == null ? null : int.tryParse(e.statusCode!);

  bool hasAny(List<String> needles) =>
      needles.any((n) => code.contains(n) || message.contains(n));

  // Account already exists (Supabase answers 422 "User already registered").
  if (hasAny(['user_already_exists', 'user already registered', 'already been registered', 'already exists'])) {
    return 'An account with this email already exists. Try signing in instead.';
  }
  // Invalid credentials (sign-in).
  if (hasAny(['invalid login credentials', 'invalid_login_credentials', 'invalid credentials'])) {
    return 'That email and password don\u2019t match our records. Check them and try again.';
  }
  // Malformed / unusable email address.
  if (hasAny(['invalid email', 'invalid_email', 'unable to validate email', 'email address is invalid', 'email format'])) {
    return 'That email address doesn\u2019t look right. Check it and try again.';
  }
  // Weak password (Supabase minimum is 6 characters).
  if (hasAny(['weak password', 'weak_password', 'password should be', 'password is too short', 'password must be'])) {
    return 'Please choose a password with at least 6 characters.';
  }
  // Rate limiting (HTTP 429 or provider rate-limit codes).
  if (status == 429 ||
      hasAny(['over_email_send_rate_limit', 'rate limit', 'rate_limit', 'too many requests', 'security purposes'])) {
    return 'Too many attempts right now. Wait a little while and try again.';
  }
  // Email confirmation still required by the hosted project (see README:
  // disable "Confirm Email" for the intended immediate-session flow).
  if (hasAny(['email not confirmed', 'email_not_confirmed', 'confirmation', 'verify your email', 'email confirmation'])) {
    return 'Please check your email and tap the confirmation link, then sign in.';
  }
  // Fallback: surface the service message only when it is short and free
  // of technical artifacts; otherwise use the generic message. Never leak
  // URLs, tokens, or stack content.
  final raw = e.message.trim();
  if (raw.isNotEmpty &&
      raw.length <= 120 &&
      !raw.contains('http') &&
      !raw.contains('Socket') &&
      !raw.contains('Exception') &&
      !raw.contains('\n')) {
    return raw;
  }
  return 'Something went wrong. Please try again.';
}

/// Client-side email check. Returns a user-facing message or null when ok.
String? validateAuthEmail(String email) {
  final value = email.trim();
  if (value.isEmpty) return 'Please enter your email address.';
  if (value.length > 254 ||
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return 'That email address doesn\u2019t look right. Check it and try again.';
  }
  return null;
}

/// Client-side password check. Returns a user-facing message or null when ok.
String? validateAuthPassword(String password, {required bool isSignup}) {
  if (password.isEmpty) return 'Please enter your password.';
  if (isSignup && password.length < 6) {
    return 'Password must be at least 6 characters long.';
  }
  return null;
}

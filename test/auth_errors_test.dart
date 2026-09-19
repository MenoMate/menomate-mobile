import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:menomate_mobile/core/auth_errors.dart';

/// Auth error-mapping contract (Phase 1).
///
/// Every failure mode the signup/sign-in flows must handle maps to a clean
/// user-facing message. These tests assert on the real mapping used by
/// `AuthScreen` — never on faked UI states. No message may leak raw
/// exceptions, URLs, or secrets.
void main() {
  group('isAuthNetworkError', () {
    test('flags transport failures', () {
      expect(
        isAuthNetworkError(
          const SocketException('Failed host lookup', osError: OSError()),
        ),
        isTrue,
      );
      expect(
        isAuthNetworkError(
          const SocketException('No address associated with hostname'),
        ),
        isTrue,
      );
      expect(isAuthNetworkError(const HttpException('closed')), isTrue);
      expect(isAuthNetworkError(TimeoutException('timed out')), isTrue);
      // package:http ClientException text wrapping the same OS failures.
      expect(
        isAuthNetworkError(
          Exception(
            'ClientException with SocketException: Failed host lookup',
          ),
        ),
        isTrue,
      );
      expect(
        isAuthNetworkError(Exception('Connection refused, errno = 111')),
        isTrue,
      );
      expect(
        isAuthNetworkError(Exception('Network is unreachable')),
        isTrue,
      );
    });

    test('does not flag credential problems', () {
      expect(
        isAuthNetworkError(
          const AuthException('Invalid login credentials'),
        ),
        isFalse,
      );
      expect(isAuthNetworkError(Exception('User already registered')), isFalse);
    });
  });

  group('friendlyAuthErrorMessage', () {
    test('network failure gives an offline message, never raw errors', () {
      final message = friendlyAuthErrorMessage(
        const SocketException('Failed host lookup: xyz.supabase.co'),
      );
      expect(message, contains('connection'));
      expect(message, isNot(contains('SocketException')));
      expect(message, isNot(contains('supabase.co')));
      expect(message, isNot(contains('errno')));
    });

    test('duplicate signup directs to sign-in', () {
      final message = friendlyAuthErrorMessage(
        const AuthException('User already registered', statusCode: '422'),
      );
      expect(message, contains('already exists'));
      expect(message, contains('signing in'));
    });

    test('invalid credentials stay generic but clean', () {
      final message = friendlyAuthErrorMessage(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );
      expect(message, contains('don\u2019t match'));
      expect(message, isNot(contains('Invalid login credentials')));
    });

    test('invalid email is flagged plainly', () {
      final message = friendlyAuthErrorMessage(
        const AuthException('Unable to validate email address', statusCode: '400'),
      );
      expect(message, contains('email'));
    });

    test('weak password asks for a longer one', () {
      final message = friendlyAuthErrorMessage(
        const AuthException(
          'Password should be at least 6 characters',
          statusCode: '422',
        ),
      );
      expect(message, contains('6 characters'));
    });

    test('rate limiting asks for patience, not retry spam', () {
      final message = friendlyAuthErrorMessage(
        const AuthException(
          'You have made too many requests',
          statusCode: '429',
        ),
      );
      expect(message, contains('Wait'));
      expect(
        friendlyAuthErrorMessage(
          const AuthException('over_email_send_rate_limit', statusCode: '429'),
        ),
        contains('Wait'),
      );
    });

    test('unexpected failures never leak internals', () {
      for (final e in [
        Exception('coffee'),
        const AuthException(
          'https://xyz.supabase.co/auth/v1/signup failed: SocketException: boom\nstack trace here',
          statusCode: '500',
        ),
      ]) {
        final message = friendlyAuthErrorMessage(e);
        expect(message, isNot(contains('http')));
        expect(message, isNot(contains('Socket')));
        expect(message, isNot(contains('Exception')));
        expect(message, isNot(contains('\n')));
        expect(message.isNotEmpty, isTrue);
      }
    });
  });

  group('client-side validation', () {
    test('email validation', () {
      expect(validateAuthEmail(''), contains('email'));
      expect(validateAuthEmail('not-an-email'), isNotNull);
      expect(validateAuthEmail('a@b'), isNotNull);
      expect(validateAuthEmail('user@example.com'), isNull);
      expect(validateAuthEmail('  user@example.com  '), isNull);
    });

    test('password validation', () {
      expect(
        validateAuthPassword('', isSignup: true),
        contains('password'),
      );
      expect(
        validateAuthPassword('12345', isSignup: true),
        contains('6 characters'),
      );
      expect(validateAuthPassword('123456', isSignup: true), isNull);
      // Sign-in accepts any non-empty password (server decides).
      expect(validateAuthPassword('x', isSignup: false), isNull);
    });
  });
}

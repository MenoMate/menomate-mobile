import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/core/env.dart';

/// Release-hardening contract for [Env].
///
/// Debug behavior is unchanged (loopback default); release/profile builds
/// can never silently resolve to a development-only endpoint. The
/// production-injection case (`--dart-define=API_BASE_URL=...`) is verified
/// by running this file with the define (see README "Release builds").
void main() {
  group('isDevelopmentEndpoint', () {
    test('flags loopback endpoints', () {
      expect(Env.isDevelopmentEndpoint('http://127.0.0.1:8000'), isTrue);
      expect(Env.isDevelopmentEndpoint('http://127.0.0.1:8000/'), isTrue);
      expect(Env.isDevelopmentEndpoint('http://localhost:8000'), isTrue);
      expect(Env.isDevelopmentEndpoint('http://localhost/'), isTrue);
      expect(Env.isDevelopmentEndpoint('http://[::1]:8000/'), isTrue);
    });

    test('flags emulator and LAN endpoints', () {
      expect(Env.isDevelopmentEndpoint('http://10.0.2.2:8000'), isTrue);
      expect(
        Env.isDevelopmentEndpoint('http://192.168.1.50:8000'),
        isTrue,
      );
      expect(Env.isDevelopmentEndpoint('http://10.0.0.5:8000'), isTrue);
      expect(Env.isDevelopmentEndpoint('http://172.16.0.2:8000'), isTrue);
    });

    test('accepts the production backend', () {
      expect(
        Env.isDevelopmentEndpoint('https://menomate-api.onrender.com'),
        isFalse,
      );
      expect(
        Env.isDevelopmentEndpoint(Env.productionApiUrl),
        isFalse,
      );
    });

    test('treats unparseable/empty as unsafe', () {
      expect(Env.isDevelopmentEndpoint(''), isTrue);
      expect(Env.isDevelopmentEndpoint('not a url'), isTrue);
    });
  });

  group('apiUrl resolution', () {
    test('injected define always wins', () {
      // This file is also executed with
      // --dart-define=API_BASE_URL=https://menomate-api.onrender.com
      // during release verification; without the define the debug
      // default below applies instead.
      const injected = String.fromEnvironment('API_BASE_URL');
      if (injected.isNotEmpty) {
        expect(Env.apiUrl, injected);
        expect(Env.isDevelopmentEndpoint(Env.apiUrl), isFalse);
      } else {
        // Plain `flutter test` runs in debug: loopback default preserved.
        expect(Env.apiUrl, Env.debugApiUrl);
      }
    });

    test('release fallback constant is the production backend', () {
      expect(
        Env.productionApiUrl,
        'https://menomate-api.onrender.com',
      );
      expect(Env.isDevelopmentEndpoint(Env.productionApiUrl), isFalse);
      expect(
        Env.isDevelopmentEndpoint(Env.debugApiUrl),
        isTrue,
      );
    });
  });
}

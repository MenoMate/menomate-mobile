import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';

/// (10) Care offline: in widget tests the connectivity plugin has no host
/// implementation, so the platform call fails — the tab must fail closed
/// into the internet-required state (same path as real airplane mode).
void main() {
  testWidgets(
      'Care offline shows internet-required state, no spinner, no AI reply',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AssistantTab()),
      ),
    );
    await tester.pumpAndSettle();

    // Send a message via a canonical empty-state quick chip
    // (single prompt system; the duplicate bottom bar was removed).
    await tester.tap(find.text('Help with my current pain'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('needs an internet connection'), findsWidgets);
    // No endless loading indicator once the offline reply lands.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('MenoMate Care is thinking...'), findsNothing);
  });
}

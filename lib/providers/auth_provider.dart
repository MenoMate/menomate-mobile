import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// A StreamProvider that listens to Supabase auth state changes and yields the current User (or null).
final authStateProvider = StreamProvider<User?>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  // Yield the already-restored session user immediately so initial routing has the session without delay
  yield supabase.auth.currentSession?.user;
  yield* supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

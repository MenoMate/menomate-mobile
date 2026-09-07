import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));

  // Interceptor to inject the Supabase JWT token into every request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      return handler.next(options);
    },
  ));

  return dio;
});

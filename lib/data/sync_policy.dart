import 'package:dio/dio.dart';

/// Local-first data states. A network failure is NEVER represented as
/// [NoData]; use [Unavailable] when nothing local exists and remote fails,
/// or [Cached]/[PendingSync] when local data is shown instead.
sealed class DataState<T> {
  const DataState();
}

/// No local data exists (and remote has not contradicted that).
class NoData<T> extends DataState<T> {
  const NoData();
}

/// Local data confirmed by a successful remote round-trip.
class Fresh<T> extends DataState<T> {
  final T data;
  const Fresh(this.data);
}

/// Local data shown while remote is unreachable or refresh failed.
/// [fetchedAt] records when the server data was obtained. There is no
/// cache-expiry policy: cached values remain displayable until replaced.
class Cached<T> extends DataState<T> {
  final T data;
  final DateTime fetchedAt;
  const Cached(this.data, this.fetchedAt);
}

/// Local data exists with one or more rows still awaiting sync.
class PendingSync<T> extends DataState<T> {
  final T data;
  const PendingSync(this.data);
}

/// Nothing usable: no local data and remote unreachable/failed.
class Unavailable<T> extends DataState<T> {
  final String message;
  const Unavailable(this.message);
}

/// Local data kept, but the server rejected an item (400/409).
/// Only the conflicting item is flagged; independent rows are unaffected.
class ConflictState<T> extends DataState<T> {
  final T data;
  final String message;
  const ConflictState(this.data, this.message);
}

/// Typed remote failures so repositories can distinguish no-data from
/// network/auth/server/conflict outcomes.
sealed class ApiError implements Exception {
  const ApiError();
  String get message;
}

/// No response: connection error, timeout, or other transport failure.
class NetworkUnavailable extends ApiError {
  const NetworkUnavailable([this.detail = 'No internet connection.']);
  final String detail;
  @override
  String get message => detail;
}

/// 401: session expired/invalid. Never blindly retried.
class AuthFailure extends ApiError {
  const AuthFailure([this.detail = 'Session expired. Please sign in again.']);
  final String detail;
  @override
  String get message => detail;
}

/// 400/409: server rejected the payload. Marks only that row `conflict`.
class Conflict extends ApiError {
  const Conflict(this.detail);
  final String detail;
  @override
  String get message => detail;
}

/// 422: payload failed server validation. Surfaced like [Conflict]
/// (retrying an identical payload can never succeed); never retried blindly.
class ValidationError extends ApiError {
  const ValidationError([this.detail = 'Some entries need attention.']);
  final String detail;
  @override
  String get message => detail;
}

/// 5xx or unexpected status: keep row pending, retry later.
class ServerError extends ApiError {
  const ServerError([this.detail = 'Server error. Will retry later.']);
  final String detail;
  @override
  String get message => detail;
}

/// Maps a Dio failure to a typed [ApiError]. Pure transport mapping;
/// no business logic.
ApiError mapDioException(DioException e) {
  if (e.response != null) {
    final status = e.response!.statusCode ?? 0;
    final detail = _responseDetail(e.response!.data);
    if (status == 401) return AuthFailure(detail ?? 'Session expired.');
    // 403 (valid session, forbidden resource) is an auth-scope failure:
    // never blindly retried, surfaced like an expired session.
    if (status == 403) {
      return AuthFailure(detail ?? 'Access denied. Please sign in again.');
    }
    if (status == 422) {
      return ValidationError(detail ?? 'Some entries need attention.');
    }
    if (status == 400 || status == 409) {
      return Conflict(detail ?? 'Server rejected this entry.');
    }
    if (status >= 500) return ServerError(detail ?? 'Server error.');
    return ServerError(detail ?? 'Request failed (status $status).');
  }
  return NetworkUnavailable(e.message ?? 'No internet connection.');
}

String? _responseDetail(dynamic data) {
  if (data is Map && data['detail'] != null) {
    return data['detail'].toString();
  }
  return null;
}

/// Outcome of one sync attempt, shared by all repositories.
enum SyncOutcome {
  /// 2xx: mark row synced, reconcile server IDs.
  synced,

  /// 400/409: mark only that row conflict, continue with later rows.
  conflict,

  /// Network error or 5xx: keep row pending, stop this pass, retry later.
  retryLater,

  /// 401: stop, surface auth state explicitly. Never auto-retry.
  authError,
}

SyncOutcome classifySyncError(ApiError e) {
  return switch (e) {
    Conflict() || ValidationError() => SyncOutcome.conflict,
    NetworkUnavailable() || ServerError() => SyncOutcome.retryLater,
    AuthFailure() => SyncOutcome.authError,
  };
}

/// Shared read helpers for UI layers rendering [DataState].
extension DataStateX<T> on DataState<T> {
  /// The usable payload, or null for [NoData]/[Unavailable].
  T? get dataOrNull => switch (this) {
    Fresh(data: final d) => d,
    Cached(data: final d) => d,
    PendingSync(data: final d) => d,
    ConflictState(data: final d) => d,
    _ => null,
  };
}

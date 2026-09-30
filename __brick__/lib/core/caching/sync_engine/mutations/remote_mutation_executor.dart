import 'package:dio/dio.dart';
import 'package:{{project_name}}/core/caching/models/remote_mutation_response.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/retry_policy.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';
import 'package:{{project_name}}/core/network/i_http_client.dart';

class RemoteMutationExecutor {
  RemoteMutationExecutor({
    required IHttpClient httpClient,
    required RetryPolicy retryPolicy,
    required ISyncStateStore syncStateStore,
  }) : _httpClient = httpClient,
       _retryPolicy = retryPolicy,
       _syncStateStore = syncStateStore;

  final IHttpClient _httpClient;
  final RetryPolicy _retryPolicy;
  final ISyncStateStore _syncStateStore;
  final _log = AppLogger.logger;

  Future<List<RemoteMutationResponse>> execute(
    List<MutationData> pendingMutations,
  ) async {
    final futures = pendingMutations.map(_executeOne);
    return Future.wait(futures);
  }

  Future<RemoteMutationResponse> _executeOne(
    MutationData pendingMutation,
  ) async {
    return _retryMutation(
      pendingMutation,
      _buildHttpRequest(pendingMutation),
      0,
    );
  }

  Future<RemoteMutationResponse> _buildHttpRequest(
    MutationData pendingMutation,
  ) {
    switch (pendingMutation.operationType) {
      case MutationType.create:
        return _safeRequest(
          _httpClient.post(
            "/${pendingMutation.entityType}",
            data: pendingMutation.payload,
            headers: {'Idempotency-Key': pendingMutation.etag},
          ),
          pendingMutation,
        );
      case MutationType.update:
        return _safeRequest(
          _httpClient.put(
            "/${pendingMutation.entityType}/${pendingMutation.entityId}",
            data: pendingMutation.payload,
            headers: {'If-Match': pendingMutation.etag},
          ),
          pendingMutation,
        );
      case MutationType.delete:
        return _safeRequest(
          _httpClient.delete(
            "/${pendingMutation.entityType}/${pendingMutation.entityId}",
            headers: {'If-Match': pendingMutation.etag},
          ),
          pendingMutation,
        );
    }
  }

  Future<RemoteMutationResponse> _safeRequest(
    Future<Response> request,
    MutationData mutation,
  ) async {
    try {
      await _syncStateStore.markInProgress(mutation);
      final response = await request;
      if (mutation.operationType == MutationType.create) {
        if (response.headers.value('ETag') == null) {
          _log.severe(
            NetworkException.etagMissing().message,
            NetworkException.etagMissing(),
          );
          return RemoteMutationResponse.error(
            errorType: RemoteMutationErrorType.missingHeader,
            mutation: mutation,
          );
        }
        return RemoteMutationResponse.createSuccess(
          mutation: mutation,
          etag: response.headers.value('ETag')!,
          responseData: response.data,
        );
      }

      return RemoteMutationResponse.success(
        mutation: mutation,
        responseData: response.data,
      );
    } on DioException catch (e) {
      return await _handleSafeRequestDioException(mutation, e);
    } catch (e) {
      _log.severe("Network request failed for mutation id ${mutation.id}.", e);
      return RemoteMutationResponse.error(
        errorType: RemoteMutationErrorType.unknown,
        mutation: mutation,
      );
    }
  }

  Future<RemoteMutationResponse> _handleSafeRequestDioException(
    MutationData mutation,
    DioException e,
  ) async {
    if (e.type == DioExceptionType.badResponse) {
      if (e.response?.statusCode == 404) {
        return RemoteMutationResponse.error(
          errorType: RemoteMutationErrorType.badRequest,
          mutation: mutation,
        );
      } else if (e.response?.statusCode == 403) {
        return RemoteMutationResponse.error(
          errorType: RemoteMutationErrorType.forbidden,
          mutation: mutation,
        );
      } else if (e.response?.statusCode == 412) {
        // fetch remote version
        final response = await _retryFetch(mutation, 0);
        if (response == null ||
            response.data == null ||
            response.headers.value('ETag') == null) {
          return RemoteMutationResponse.error(
            errorType: RemoteMutationErrorType.unresolvedConflict,
            mutation: mutation,
          );
        }
        return RemoteMutationResponse.conflict(
          mutation: mutation,
          etag: response.headers.value('ETag')!,
          serverRepresentation: response.data,
        );
      }
    } else if (e.type == DioExceptionType.cancel) {
      return RemoteMutationResponse.error(
        errorType: RemoteMutationErrorType.cancelled,
        mutation: mutation,
      );
    } else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return RemoteMutationResponse.error(
        errorType: RemoteMutationErrorType.connectionError,
        mutation: mutation,
      );
    }
    return RemoteMutationResponse.error(
      errorType: RemoteMutationErrorType.unknown,
      mutation: mutation,
    );
  }

  Future<RemoteMutationResponse> _retryMutation(
    MutationData mutation,
    Future<RemoteMutationResponse> request,
    int attempt,
  ) async {
    final response = await request;

    if (response is RemoteMutationError &&
        response.errorType == RemoteMutationErrorType.connectionError &&
        _retryPolicy.shouldRetry(attempt)) {
      final delay = _retryPolicy.getDelayForAttempt(attempt);
      _log.warning(
        "Retrying network request for mutation $mutation in ${delay}s, attempt number $attempt",
      );
      await Future.delayed(delay);
      return _retryMutation(mutation, request, attempt + 1);
    }

    return response;
  }

  Future<Response?> _retryFetch(MutationData mutation, int attempt) async {
    try {
      return await _httpClient.get(
        '/${mutation.entityType}/${mutation.entityId}',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // retry
        if (_retryPolicy.shouldRetry(attempt)) {
          final delay = _retryPolicy.getDelayForAttempt(attempt);
          _log.warning(
            "Retrying network request GET /${mutation.entityType}/${mutation.entityId} in ${delay}s, attempt number $attempt",
          );
          await Future.delayed(delay);
          return _retryFetch(mutation, attempt + 1);
        }
      }
      _logFetchError(mutation.entityType, mutation.entityId, e);
      return null;
    } catch (e) {
      _logFetchError(mutation.entityType, mutation.entityId, e);
      return null;
    }
  }

  void _logFetchError(String entityType, String entityId, Object e) {
    _log.severe(
      'RemoteMutationExecutor failed to fetch a resource after a conflict: path /$entityType/$entityId',
      e,
    );
  }
}

import 'package:dio/dio.dart';
import 'package:{{project_name}}/core/caching/models/remote_mutation_response.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/network/i_entity_remote_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/models/valid_mutation_data.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/retry_policy.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_remote_mutation_executor.dart';
import 'package:{{project_name}}/core/data/models/remote/api_response_model.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';

class RemoteMutationExecutor implements IRemoteMutationExecutor {
  RemoteMutationExecutor({
    required IEntityRemoteDatasourceRegistry remoteDatasourceRegistry,
    required RetryPolicy retryPolicy,
    required ISyncStateStore syncStateStore,
  }) : _remoteDatasourceRegistry = remoteDatasourceRegistry,
       _retryPolicy = retryPolicy,
       _syncStateStore = syncStateStore;

  final IEntityRemoteDatasourceRegistry _remoteDatasourceRegistry;
  final RetryPolicy _retryPolicy;
  final ISyncStateStore _syncStateStore;
  final _log = AppLogger.logger;

  @override
  Future<List<RemoteMutationResponse>> execute(
    List<ValidMutationData> pendingMutations,
  ) async {
    final futures = pendingMutations.map(_executeOne);
    return Future.wait(futures);
  }

  Future<RemoteMutationResponse> _executeOne(
    ValidMutationData pendingMutation,
  ) async {
    return _retryMutation(
      pendingMutation,
      _buildHttpRequest(pendingMutation),
      0,
    );
  }

  Future<RemoteMutationResponse> _buildHttpRequest(
    ValidMutationData pendingMutation,
  ) {
    return switch (pendingMutation.operationType) {
      MutationType.create => _safeRequest(
        _remoteDatasourceRegistry
            .get(pendingMutation.entityType)
            .add(pendingMutation.payload),
        // _httpClient.post(
        //   "/${pendingMutation.entityType}",
        //   data: pendingMutation.payload!,
        //   headers: {'Idempotency-Key': pendingMutation.etag},
        // ),
        pendingMutation,
      ),
      MutationType.update => _safeRequest(
        _remoteDatasourceRegistry
            .get(pendingMutation.entityType)
            .update(pendingMutation.entityRemoteId!, pendingMutation.payload),
        // _httpClient.put(
        //   "/${pendingMutation.entityType}/${pendingMutation.entityRemoteId}",
        //   data: pendingMutation.payload!,
        //   headers: {'If-Match': pendingMutation.etag},
        // ),
        pendingMutation,
      ),
      MutationType.delete => _safeRequest(
        _remoteDatasourceRegistry
            .get(pendingMutation.entityType)
            .delete(pendingMutation.entityRemoteId!),
        // _httpClient.delete(
        //   "/${pendingMutation.entityType}/${pendingMutation.entityRemoteId}",
        //   headers: {'If-Match': pendingMutation.etag},
        // ),
        pendingMutation,
      ),
    };
  }

  Future<RemoteMutationResponse> _safeRequest(
    Future<ApiResponseModel> request,
    ValidMutationData mutation,
  ) async {
    try {
      await _syncStateStore.markInProgress(mutation);
      final response = await request;
      if (mutation.operationType == MutationType.create) {
        if (response.etag == null) {
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
          etag: response.etag!,
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
    ValidMutationData mutation,
    DioException e,
  ) async {
    // TODO handle 409 and rate limit status code
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
            response.etag == null) {
          return RemoteMutationResponse.error(
            errorType: RemoteMutationErrorType.unresolvedConflict,
            mutation: mutation,
          );
        }
        return RemoteMutationResponse.conflict(
          mutation: mutation,
          etag: response.etag!,
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
    ValidMutationData mutation,
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

  Future<ApiResponseModel?> _retryFetch(
    ValidMutationData mutation,
    int attempt,
  ) async {
    try {
      return await _remoteDatasourceRegistry
          .get(mutation.entityType)
          .fetchById(mutation.entityRemoteId!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // retry
        if (_retryPolicy.shouldRetry(attempt)) {
          final delay = _retryPolicy.getDelayForAttempt(attempt);
          _log.warning(
            "Retrying network request GET /${mutation.entityType}/${mutation.entityRemoteId} in ${delay}s, attempt number $attempt",
          );
          await Future.delayed(delay);
          return _retryFetch(mutation, attempt + 1);
        }
      }
      _logFetchError(mutation.entityType.label, mutation.entityRemoteId!, e);
      return null;
    } catch (e) {
      _logFetchError(mutation.entityType.label, mutation.entityRemoteId!, e);
      return null;
    }
  }

  void _logFetchError(String entityType, int entityRemoteId, Object e) {
    _log.severe(
      'RemoteMutationExecutor failed to fetch a resource after a conflict: path /$entityType/$entityRemoteId',
      e,
    );
  }
}

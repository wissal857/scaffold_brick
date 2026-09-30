import 'dart:convert';

import 'package:{{project_name}}/core/logging/app_logger.dart';

enum MutationType {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  final String label;

  const MutationType(this.label);
}

//enum RefreshPolicy { immediate, background, manual } Always background

class SyncMutationRequestPayload {
  final Map<String, dynamic>? data;

  const SyncMutationRequestPayload({required this.data});
  factory SyncMutationRequestPayload.fromString(String str) {
    final log = AppLogger.logger;
    try {
      return SyncMutationRequestPayload(
        data: jsonDecode(str) as Map<String, dynamic>,
      );
    } on FormatException catch (e, s) {
      log.severe(e.message, e, s);
      return SyncMutationRequestPayload(data: null);
    }
  }

  @override
  String toString() {
    return data.toString();
  }
}

sealed class SyncMutationRequest {
  const SyncMutationRequest._({
    required this.entityType,
    required this.entityId,
    required this.mutationType,
    required this.payload,
    required this.timestamp,
  });

  factory SyncMutationRequest.create({
    required String entityType,
    required String entityId,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
  }) = SyncCreateRequest._;

  factory SyncMutationRequest.delete({
    required String entityType,
    required String entityId,
    required String etag,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
  }) = SyncDeleteRequest._;

  factory SyncMutationRequest.update({
    required String entityType,
    required String entityId,
    required String etag,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> previousPayload,
    required DateTime timestamp,
    required Set<String> dirtyFields,
  }) = SyncUpdateRequest._;

  final String entityType;

  // Assigned type String because it can hold the idempotencyKey
  final String entityId;
  final MutationType mutationType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  @override
  String toString() {
    return "SyncRequest -> entityType: $entityType, entityId: $entityId, mutationType: ${mutationType.label}, timestamp: $timestamp, payload: ${payload.toString()}";
  }
}

final class SyncCreateRequest extends SyncMutationRequest {
  SyncCreateRequest._({
    required super.entityType,
    required super.entityId,
    required this.idempotencyKey,
    super.mutationType = MutationType.create,
    required super.payload,
    required super.timestamp,
  }) : super._();

  final String idempotencyKey;
}

final class SyncDeleteRequest extends SyncMutationRequest {
  SyncDeleteRequest._({
    required super.entityType,
    required super.entityId,
    required this.etag,
    super.mutationType = MutationType.delete,
    required super.payload,
    required super.timestamp,
  }) : super._();

  final String etag;
}

final class SyncUpdateRequest extends SyncMutationRequest {
  const SyncUpdateRequest._({
    required super.entityType,
    required super.entityId,
    required this.etag,
    super.mutationType = MutationType.update,
    required super.payload,
    required this.previousPayload,
    required super.timestamp,
    required this.dirtyFields,
  }) : super._();

  final Set<String> dirtyFields;
  final Map<String, dynamic> previousPayload;
  final String etag;

  @override
  String toString() {
    return "SyncRequest -> entityType: $entityType, entityId: $entityId, mutationType: ${mutationType.label}, timestamp: $timestamp, payload: ${payload.toString()}, dirtyFields: ${dirtyFields.toString()}, previousPayload: $previousPayload";
  }
}

import 'dart:convert';

import '../../../services/bff/bff_client.dart';
import '../domain/sync_models.dart';
import '../domain/sync_ports.dart';
import 'sync_dto.dart';

class SyncGatewayException implements Exception {
  final int? statusCode;
  final String code;
  final String? correlationId;
  final bool retryable;

  const SyncGatewayException({
    this.statusCode,
    required this.code,
    this.correlationId,
    required this.retryable,
  });

  @override
  String toString() => 'SyncGatewayException($code, $statusCode)';
}

class BffSyncGateway implements SyncGateway {
  final BffClient client;
  const BffSyncGateway(this.client);

  @override
  Future<SyncPage> synchronize({
    required String userId,
    required String bearerToken,
    required String deviceId,
    required bool bootstrap,
    required String? cursor,
    required List<SyncOperation> mutations,
  }) async {
    try {
      final response = await client.post(
        'users/${Uri.encodeComponent(userId)}/sync',
        SyncRequestDto(
          deviceId: deviceId,
          bootstrap: bootstrap,
          cursor: cursor,
          mutations: mutations,
        ).toJson(),
        bearerToken: bearerToken,
      );
      final decoded = response.body.isEmpty
          ? <String, Object?>{}
          : (jsonDecode(response.body) as Map).cast<String, Object?>();
      if (!response.isSuccess) {
        throw SyncGatewayException(
          statusCode: response.statusCode,
          code: decoded['code'] as String? ?? 'SYNC_HTTP_ERROR',
          correlationId: decoded['correlationId'] as String?,
          retryable: response.statusCode == 429 || response.statusCode >= 500,
        );
      }
      return SyncResponseDto.fromJson(decoded).page;
    } on SyncGatewayException {
      rethrow;
    } catch (_) {
      throw const SyncGatewayException(
        code: 'NETWORK_UNAVAILABLE',
        retryable: true,
      );
    }
  }
}

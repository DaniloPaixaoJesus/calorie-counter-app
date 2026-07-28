import 'package:flutter/foundation.dart';

import '../domain/sync_models.dart';
import '../domain/sync_ports.dart';
import '../domain/sync_types.dart';
import '../infrastructure/bff_sync_gateway.dart';
import '../infrastructure/sync_diagnostics.dart';

class SyncCoordinator extends ChangeNotifier {
  final SyncStore store;
  final SyncGateway gateway;
  final SyncSession session;
  final SyncClock clock;
  final String deviceId;
  final SyncDiagnostics diagnostics;
  final Future<void> Function()? onDataChanged;

  SyncStatus _status = SyncStatus.idle;
  int _pendingCount = 0;
  String? _lastErrorCode;
  bool _running = false;
  Future<bool>? _activeSynchronization;

  SyncCoordinator({
    required this.store,
    required this.gateway,
    required this.session,
    required this.deviceId,
    this.clock = const SystemSyncClock(),
    this.diagnostics = const NoopSyncDiagnostics(),
    this.onDataChanged,
  });

  SyncStatus get status => _status;
  int get pendingCount => _pendingCount;
  String? get lastErrorCode => _lastErrorCode;
  bool get isRunning => _running;

  Future<void> initialize() async {
    await store.recoverSending();
    await refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = (await store.pendingOperations(limit: 1000000)).length;
    if (!_running && _pendingCount > 0 && _status == SyncStatus.idle) {
      _status = SyncStatus.pending;
    }
    notifyListeners();
  }

  Future<bool> bootstrap() => synchronize(forceBootstrap: true);
  Future<bool> retry() => synchronize();
  Future<bool> flush() => synchronize();

  Future<bool> synchronize({bool forceBootstrap = false}) async {
    final active = _activeSynchronization;
    if (active != null) return active;
    final synchronization = _synchronize(forceBootstrap: forceBootstrap);
    _activeSynchronization = synchronization;
    try {
      return await synchronization;
    } finally {
      if (identical(_activeSynchronization, synchronization)) {
        _activeSynchronization = null;
      }
    }
  }

  Future<bool> _synchronize({required bool forceBootstrap}) async {
    final userId = session.userId;
    final token = session.bearerToken;
    if (userId == null || token == null || token.isEmpty) {
      _setStatus(SyncStatus.authenticationRequired);
      return false;
    }
    if (!session.isPremiumActive) {
      await refreshPendingCount();
      _setStatus(SyncStatus.pausedPremium);
      return false;
    }

    _running = true;
    _setStatus(SyncStatus.syncing);
    final startedAt = clock.now();
    var sentIds = <String>[];
    try {
      var checkpoint = await store.checkpoint(userId) ??
          SyncCheckpoint(ownerUserId: userId, deviceId: deviceId);
      final isBootstrap = forceBootstrap ||
          checkpoint.bootstrapState != BootstrapState.completed;
      if (isBootstrap && checkpoint.bootstrapState != BootstrapState.running) {
        checkpoint =
            checkpoint.copyWith(bootstrapState: BootstrapState.running);
        await store.saveCheckpoint(checkpoint);
      }

      var hasMoreRemoteChanges = true;
      var cycles = 0;
      while (hasMoreRemoteChanges ||
          (await store.pendingOperations(limit: 1)).isNotEmpty) {
        if (++cycles > 10000) {
          throw StateError('Limite de páginas de sincronização excedido');
        }
        final pending = await store.pendingOperations(limit: 100);
        sentIds = pending.map((item) => item.operationId).toList();
        await store.markSending(sentIds, clock.now());
        final page = await gateway.synchronize(
          userId: userId,
          bearerToken: token,
          deviceId: checkpoint.deviceId,
          bootstrap: isBootstrap,
          cursor: checkpoint.cursor,
          mutations: pending,
        );
        if (!page.premiumActive) {
          await store.fail(sentIds, 'PREMIUM_REQUIRED');
          _setStatus(SyncStatus.pausedPremium, errorCode: 'PREMIUM_REQUIRED');
          return false;
        }
        await store.transaction(() async {
          await store.applyRemoteChanges(
            page.results.map((result) => result.canonicalChange).toList(),
            remoteWins: isBootstrap,
            ownerUserId: userId,
          );
          await store.applyRemoteChanges(
            page.changes,
            remoteWins: isBootstrap,
            ownerUserId: userId,
          );
          await store.acknowledge(
              page.results.map((result) => result.operationId).toList());
          final acknowledged =
              page.results.map((result) => result.operationId).toSet();
          final missing = sentIds
              .where((operationId) => !acknowledged.contains(operationId));
          await store.fail(missing.toList(), 'SYNC_MISSING_ACK');
          checkpoint = checkpoint.copyWith(cursor: page.nextCursor);
          await store.saveCheckpoint(checkpoint);
        });
        hasMoreRemoteChanges = page.hasMore;
        await onDataChanged?.call();
      }
      if (isBootstrap) {
        await store.transaction(() async {
          await store.associateAnonymousData(userId);
          checkpoint = checkpoint.copyWith(
            bootstrapState: BootstrapState.completed,
            lastSuccessAt: clock.now(),
          );
          await store.saveCheckpoint(checkpoint);
        });
      } else {
        await store
            .saveCheckpoint(checkpoint.copyWith(lastSuccessAt: clock.now()));
      }
      await refreshPendingCount();
      _setStatus(_pendingCount == 0 ? SyncStatus.updated : SyncStatus.pending);
      diagnostics.record(
        event: 'success',
        pendingCount: _pendingCount,
        elapsed: clock.now().difference(startedAt),
      );
      return true;
    } on SyncGatewayException catch (error) {
      await store.fail(sentIds, error.code);
      await refreshPendingCount();
      final status = error.statusCode == 401
          ? SyncStatus.authenticationRequired
          : error.statusCode == 403
              ? SyncStatus.pausedPremium
              : SyncStatus.recoverableError;
      _setStatus(status, errorCode: error.code);
      diagnostics.record(
        event: 'failure',
        errorCode: error.code,
        pendingCount: _pendingCount,
        elapsed: clock.now().difference(startedAt),
      );
      return false;
    } catch (_) {
      await store.fail(sentIds, 'SYNC_UNEXPECTED');
      await refreshPendingCount();
      _setStatus(SyncStatus.recoverableError, errorCode: 'SYNC_UNEXPECTED');
      diagnostics.record(
        event: 'failure',
        errorCode: 'SYNC_UNEXPECTED',
        pendingCount: _pendingCount,
      );
      return false;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void _setStatus(SyncStatus value, {String? errorCode}) {
    _status = value;
    _lastErrorCode = errorCode;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../application/sync_coordinator.dart';
import '../application/sync_trigger_service.dart';
import '../domain/sync_types.dart';

class SyncViewModel extends ChangeNotifier {
  final SyncCoordinator _coordinator;
  final SyncTriggerService? _triggers;

  SyncViewModel(this._coordinator, {SyncTriggerService? triggers})
      : _triggers = triggers {
    _coordinator.addListener(_relay);
    _triggers?.start();
  }

  SyncStatus get status => _coordinator.status;
  int get pendingCount => _coordinator.pendingCount;
  String? get lastErrorCode => _coordinator.lastErrorCode;
  bool get isRunning => _coordinator.isRunning;

  Future<void> retry() => _triggers?.retryNow() ?? _coordinator.retry();

  void _relay() => notifyListeners();

  @override
  void dispose() {
    _coordinator.removeListener(_relay);
    _triggers?.dispose();
    super.dispose();
  }
}

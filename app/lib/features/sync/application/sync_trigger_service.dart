import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/sync_types.dart';
import 'sync_coordinator.dart';

class SyncTriggerService with WidgetsBindingObserver {
  final SyncCoordinator coordinator;
  final Duration initialBackoff;
  final Duration maximumBackoff;
  Timer? _timer;
  int _attempt = 0;

  SyncTriggerService({
    required this.coordinator,
    this.initialBackoff = const Duration(seconds: 2),
    this.maximumBackoff = const Duration(minutes: 2),
  });

  Future<void> onMutation() => _attemptSync();
  Future<void> onForeground() => _attemptSync();
  Future<void> onPremiumRenewed() => _attemptSync();
  Future<void> retryNow() {
    _timer?.cancel();
    _attempt = 0;
    return _attemptSync();
  }

  Future<void> _attemptSync() async {
    final success = await coordinator.synchronize();
    if (success) {
      _attempt = 0;
      _timer?.cancel();
      return;
    }
    if (coordinator.status == SyncStatus.authenticationRequired ||
        coordinator.status == SyncStatus.pausedPremium) {
      _timer?.cancel();
      return;
    }
    final multiplier = 1 << _attempt.clamp(0, 6);
    final candidate = initialBackoff * multiplier;
    final delay = candidate > maximumBackoff ? maximumBackoff : candidate;
    _attempt++;
    _timer?.cancel();
    _timer = Timer(delay, _attemptSync);
  }

  void start() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onForeground());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}

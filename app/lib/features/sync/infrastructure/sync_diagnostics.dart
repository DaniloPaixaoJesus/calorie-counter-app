abstract interface class SyncDiagnostics {
  void record({
    required String event,
    String? errorCode,
    int? pendingCount,
    Duration? elapsed,
  });
}

class SafeSyncDiagnostics implements SyncDiagnostics {
  final void Function(String message) sink;
  const SafeSyncDiagnostics({required this.sink});

  @override
  void record({
    required String event,
    String? errorCode,
    int? pendingCount,
    Duration? elapsed,
  }) {
    final fields = <String>[
      'sync_event=$event',
      if (errorCode != null) 'error_code=$errorCode',
      if (pendingCount != null) 'pending_count=$pendingCount',
      if (elapsed != null) 'elapsed_ms=${elapsed.inMilliseconds}',
    ];
    sink(fields.join(' '));
  }
}

class NoopSyncDiagnostics implements SyncDiagnostics {
  const NoopSyncDiagnostics();
  @override
  void record({
    required String event,
    String? errorCode,
    int? pendingCount,
    Duration? elapsed,
  }) {}
}

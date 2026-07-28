import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/sync_types.dart';
import 'sync_view_model.dart';

class SyncStatusWidget extends StatelessWidget {
  final SyncViewModel viewModel;

  const SyncStatusWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, text, retryable) = switch (viewModel.status) {
      SyncStatus.idle => (Icons.smartphone_rounded, l10n.syncLocal, false),
      SyncStatus.pending => (
          Icons.cloud_upload_outlined,
          l10n.syncPending,
          true
        ),
      SyncStatus.syncing => (Icons.sync_rounded, l10n.syncing, false),
      SyncStatus.updated => (
          Icons.cloud_done_outlined,
          l10n.syncUpdated,
          false
        ),
      SyncStatus.pausedPremium => (
          Icons.cloud_off_outlined,
          l10n.syncPaused,
          false
        ),
      SyncStatus.authenticationRequired => (
          Icons.lock_outline_rounded,
          l10n.syncAuthRequired,
          false
        ),
      SyncStatus.recoverableError => (
          Icons.sync_problem_rounded,
          l10n.syncFailed,
          true
        ),
    };

    return Semantics(
      label: text,
      liveRegion: true,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: retryable && !viewModel.isRunning ? viewModel.retry : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (viewModel.status == SyncStatus.syncing)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(text)),
                if (viewModel.pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Text('(${viewModel.pendingCount})'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum PendingLogoutDecision { stay, erase }

Future<PendingLogoutDecision?> showPendingLogoutDialog(
  BuildContext context, {
  required int pendingCount,
}) {
  return showDialog<PendingLogoutDecision>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('Alterações ainda não sincronizadas'),
      content: Text(
        '$pendingCount ${pendingCount == 1 ? 'alteração será perdida' : 'alterações serão perdidas'} se você sair agora.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, PendingLogoutDecision.stay),
          child: const Text('Continuar no app'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, PendingLogoutDecision.erase),
          child: const Text('Sair e apagar'),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';

/// Exibe aviso quando confidence < 0.7 (FR-011).
class ConfidenceWarning extends StatelessWidget {
  final double confidence;

  const ConfidenceWarning({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    if (confidence >= 0.7) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Card(
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Estimativa com baixa confianca (${(confidence * 100).toStringAsFixed(0)}%). Revise os campos antes de confirmar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

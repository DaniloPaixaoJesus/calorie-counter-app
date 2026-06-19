import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';

/// Exibe aviso quando confidence < 0.7 (FR-011).
class ConfidenceWarning extends StatelessWidget {
  final double confidence;

  const ConfidenceWarning({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    if (confidence >= 0.7) return const SizedBox.shrink();
    const warningBackground = Color(0xFFFFF3CD);
    const warningForeground = Color(0xFF7A4D00);
    return Semantics(
      label: 'Aviso de baixa confianca da estimativa',
      liveRegion: true,
      child: Card(
        color: warningBackground,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: warningForeground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Aviso: estimativa com baixa confianca (${(confidence * 100).toStringAsFixed(0)}%). Revise os campos antes de confirmar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: warningForeground,
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

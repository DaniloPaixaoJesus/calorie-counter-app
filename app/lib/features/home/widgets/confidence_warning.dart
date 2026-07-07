import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';

/// Exibe aviso quando confidence < 0.7 (FR-011).
class ConfidenceWarning extends StatelessWidget {
  final double confidence;

  const ConfidenceWarning({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    if (confidence >= 0.7) return const SizedBox.shrink();
    const warningBackground = Color(0xFFFFF3CD);
    const warningForeground = Color(0xFF7A4D00);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.pick(
        en: 'Low confidence estimate warning',
        pt: 'Aviso de baixa confianca da estimativa',
        es: 'Aviso de baja confianza de la estimación',
      ),
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
                  l10n.pick(
                    en: 'Warning: low confidence estimate (${(confidence * 100).toStringAsFixed(0)}%). Review fields before confirming.',
                    pt: 'Aviso: estimativa com baixa confianca (${(confidence * 100).toStringAsFixed(0)}%). Revise os campos antes de confirmar.',
                    es: 'Aviso: estimación con baja confianza (${(confidence * 100).toStringAsFixed(0)}%). Revisa los campos antes de confirmar.',
                  ),
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

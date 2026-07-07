import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/premium_crown_icon.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PremiumUpgradeCard extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumUpgradeCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: const PremiumCrownIcon(size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pick(
                        en: 'Nutrity Premium',
                        pt: 'Nutrity Premium',
                        es: 'Nutrity Premium',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.pick(
                        en: 'Unlimited estimates, macros and no ads.',
                        pt: 'Estimativas ilimitadas, macros e sem anúncios.',
                        es: 'Estimaciones ilimitadas, macros y sin anuncios.',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: Text(l10n.pick(
                  en: 'Subscribe',
                  pt: 'Contratar',
                  es: 'Contratar',
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

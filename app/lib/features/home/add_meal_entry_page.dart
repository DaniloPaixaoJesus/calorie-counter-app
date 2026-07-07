import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/add_meal_page.dart';
import 'package:calorie_counter_app/features/home/widgets/action_choice_card.dart';
import 'package:calorie_counter_app/features/home/widgets/section_header.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'package:flutter/material.dart';

class AddMealEntryPage extends StatelessWidget {
  final bool showAds;
  final VoidCallback? onMealSaved;

  const AddMealEntryPage({super.key, this.showAds = true, this.onMealSaved});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LayoutBreakpoints.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: l10n.pick(
                    en: 'How do you want to\nlog your meal?',
                    pt: 'Como voce deseja\ninformar sua refeicao?',
                    es: '¿Cómo quieres\nregistrar tu comida?',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ActionChoiceCard(
                  icon: Icons.text_fields_rounded,
                  title: l10n.pick(
                    en: 'Type text',
                    pt: 'Digitar texto',
                    es: 'Escribir texto',
                  ),
                  subtitle: l10n.pick(
                    en: 'Describe what you ate',
                    pt: 'Descreva o que voce comeu',
                    es: 'Describe lo que comiste',
                  ),
                  onTap: () => Navigator.of(context).push(
                    adaptivePageRoute(
                      context: context,
                      builder: (_) => AddMealPage(
                        showAds: showAds,
                        onMealSaved: onMealSaved,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ActionChoiceCard(
                  icon: Icons.mic_rounded,
                  title: l10n.recordAudio,
                  subtitle: l10n.tellWhatYouAte,
                  onTap: () => Navigator.of(context).push(
                    adaptivePageRoute(
                      context: context,
                      builder: (_) => AddMealPage(
                        startWithAudio: true,
                        showAds: showAds,
                        onMealSaved: onMealSaved,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

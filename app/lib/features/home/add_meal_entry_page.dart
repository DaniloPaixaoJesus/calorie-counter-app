import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/add_meal_page.dart';
import 'package:calorie_counter_app/features/home/widgets/action_choice_card.dart';
import 'package:calorie_counter_app/features/home/widgets/section_header.dart';
import 'package:flutter/material.dart';

class AddMealEntryPage extends StatelessWidget {
  const AddMealEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

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
                const SectionHeader(
                  title: 'Como voce deseja\ninformar sua refeicao?',
                ),
                const SizedBox(height: AppSpacing.xl),
                ActionChoiceCard(
                  icon: Icons.text_fields_rounded,
                  title: 'Digitar texto',
                  subtitle: 'Descreva o que voce comeu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddMealPage()),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ActionChoiceCard(
                  icon: Icons.mic_rounded,
                  title: 'Gravar audio',
                  subtitle: 'Fale o que voce comeu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddMealPage(startWithAudio: true),
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

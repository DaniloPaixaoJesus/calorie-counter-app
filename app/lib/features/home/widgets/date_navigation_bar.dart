import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import '../view_model.dart';

/// Widget para navegação de data (Feature 002 - US1)
/// Exibe data selecionada formatada em PT-BR e botões de navegação
class DateNavigationBar extends StatelessWidget {
  final bool showDateLabel;

  const DateNavigationBar({
    super.key,
    this.showDateLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final formatador = DateFormat('d MMM yyyy', 'pt_BR');
    final dataFormatada = formatador.format(vm.dataSelecionada);
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.md,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: vm.podeVoltar ? vm.voltarDia : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
            ),
            if (showDateLabel) ...[
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: LayoutBreakpoints.isSmall(context) ? 112 : 136,
                child: Text(
                  dataFormatada,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: vm.podeAvancar ? vm.avancarDia : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Próximo'),
            ),
            const SizedBox(width: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: vm.eHoje ? null : vm.voltarParaHoje,
              icon: const Icon(Icons.home),
              label: const Text('Hoje'),
            ),
          ],
        ),
      ),
    );
  }
}

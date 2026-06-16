import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../view_model.dart';

/// Widget para navegação de data (Feature 002 - US1)
/// Exibe data selecionada formatada em PT-BR e botões de navegação
class DateNavigationBar extends StatelessWidget {
  const DateNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final formatador = DateFormat('EEEE, d de MMMM', 'pt_BR');
    final dataFormatada = formatador.format(vm.dataSelecionada);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Display data selecionada (FR-001)
          Text(
            dataFormatada,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Navigation buttons
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Botão Anterior (FR-006: sempre habilitado)
              ElevatedButton.icon(
                onPressed: vm.podeVoltar ? () => vm.voltarDia() : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              ),
              // Botão Próximo (FR-007: desabilitado se não puder avançar)
              ElevatedButton.icon(
                onPressed: vm.podeAvancar ? () => vm.avancarDia() : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próximo'),
              ),
              // Botão Hoje (FR-008: desabilitado se já é hoje)
              ElevatedButton.icon(
                onPressed: !vm.eHoje ? () => vm.voltarParaHoje() : null,
                icon: const Icon(Icons.home),
                label: const Text('Hoje'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

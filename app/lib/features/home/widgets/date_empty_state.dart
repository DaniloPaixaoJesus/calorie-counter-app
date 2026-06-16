import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateEmptyStateWidget extends StatelessWidget {
  final DateTime dataSelecionada;

  const DateEmptyStateWidget({
    super.key,
    required this.dataSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat('d de MMMM', 'pt_BR').format(dataSelecionada);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          'Nenhuma refeicao em $dataFormatada',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

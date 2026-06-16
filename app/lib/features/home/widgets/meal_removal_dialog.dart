import 'package:flutter/material.dart';

class MealRemovalDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const MealRemovalDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remover refeicao?'),
      content: const Text('Esta acao nao pode ser desfeita.'),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        TextButton(onPressed: onConfirm, child: const Text('Remover')),
      ],
    );
  }
}

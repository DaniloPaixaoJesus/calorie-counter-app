import 'package:flutter/material.dart';

/// Exibe aviso quando confidence < 0.7 (FR-011).
class ConfidenceWarning extends StatelessWidget {
  final double confidence;

  const ConfidenceWarning({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    if (confidence >= 0.7) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimativa com baixa confiança (${(confidence * 100).toStringAsFixed(0)}%). '
              'Revise e edite os campos antes de salvar.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

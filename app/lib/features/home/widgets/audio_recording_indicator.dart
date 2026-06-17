import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:flutter/material.dart';

class AudioRecordingIndicator extends StatelessWidget {
  final bool isRecording;
  final int secondsLeft;

  const AudioRecordingIndicator({
    super.key,
    required this.isRecording,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecording) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Gravando audio. $secondsLeft segundos restantes.',
      child: Column(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 44,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '00:${secondsLeft.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gravando...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

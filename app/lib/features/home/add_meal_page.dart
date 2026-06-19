import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/audio_transcription/audio_transcription_adapter.dart';
import 'package:calorie_counter_app/services/audio_transcription/offline_audio_transcription_adapter.dart';
import 'widgets/meal_form.dart';
import 'widgets/confidence_warning.dart';
import 'widgets/audio_recording_indicator.dart';
import 'widgets/section_header.dart';
import 'review_estimate_page.dart';
import 'view_model.dart';
import 'dart:async';

class AddMealPage extends StatefulWidget {
  final bool startWithAudio;
  final VoidCallback? onMealSaved;

  const AddMealPage({super.key, this.startWithAudio = false, this.onMealSaved});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  /// Duração máxima da gravação de áudio.
  static const Duration _maxRecordingDuration = Duration(seconds: 30);

  // Usamos o adaptador de transcrição abstrato (MVP: offline)
  final AudioTranscriptionAdapter _adapter = OfflineAudioTranscriptionAdapter();
  String _descricao = '';
  int _calorias = 0;
  bool _isListening = false;
  bool _usouAudio = false;
  Timer? _countdownTimer;
  int _segundosRestantes = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startWithAudio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vm = context.read<HomeViewModel>();
        _toggleListening(vm);
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _adapter.dispose();
    super.dispose();
  }

  void _iniciarTimer() {
    _countdownTimer?.cancel();
    _segundosRestantes = _maxRecordingDuration.inSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _segundosRestantes--);
      if (_segundosRestantes <= 0) {
        timer.cancel();
        _pararGravacao();
      }
    });
  }

  Future<void> _pararGravacao() async {
    _countdownTimer?.cancel();
    await _adapter.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _toggleListening(HomeViewModel vm) async {
    if (_isListening) {
      await _pararGravacao();
      return;
    }

    await _adapter.initialize(onError: (error) {
      if (mounted) {
        _countdownTimer?.cancel();
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no reconhecimento de voz: $error')),
        );
      }
    }, onStatus: (status) {
      if (mounted && (status == 'notListening' || status == 'done')) {
        _countdownTimer?.cancel();
        setState(() => _isListening = false);
      }
    });

    setState(() => _isListening = true);
    _iniciarTimer();
    await _adapter.startListening(
      maxDuration: _maxRecordingDuration,
      onResult: (transcricao, isFinal) {
        if (mounted && isFinal) {
          setState(() {
            _descricao = transcricao;
            _usouAudio = true;
          });
        }
      },
      onStatus: (status) {
        if (mounted && (status == 'notListening' || status == 'done')) {
          _countdownTimer?.cancel();
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _estimar(HomeViewModel vm) async {
    if (_descricao.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite pelo menos 2 caracteres.')),
      );
      return;
    }
    await vm.requestEstimate(_descricao);
    if (mounted && vm.estimate != null) {
      setState(() => _calorias = vm.estimate!.calorias);
    }
  }

  Future<void> _confirmar(HomeViewModel vm) async {
    if (_calorias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as calorias antes de salvar.')),
      );
      return;
    }
    final meal = Meal.create(
      descricao: _descricao.isNotEmpty ? _descricao : 'Sem descrição',
      calorias: _calorias,
      origem: _usouAudio ? MealOrigem.audio : MealOrigem.texto,
      dataSelecionada: vm.dataSelecionada,
      aiConfidence: vm.estimate?.confidence,
      nota: vm.estimate?.observacao,
      iconKey: vm.estimate?.iconKey,
    );
    await vm.addMeal(meal);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onMealSaved?.call();
  }

  Future<void> _revisarEConfirmar(HomeViewModel vm) async {
    final estimate = vm.estimate;
    if (estimate == null || _calorias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estime as calorias antes de confirmar.')),
      );
      return;
    }

    final result = await Navigator.of(context).push<ReviewEstimateResult>(
      MaterialPageRoute(
        builder: (_) => ReviewEstimatePage(
          descricaoInterpretada: estimate.descricaoInterpretada,
          calorias: _calorias,
          confidence: estimate.confidence,
          observacao: estimate.observacao,
          iconKey: estimate.iconKey,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _descricao = result.descricao;
      _calorias = result.calorias;
    });
    await _confirmar(vm);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final estimate = vm.estimate;
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Refeicao')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LayoutBreakpoints.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Fale o que voce comeu',
                  subtitle: 'Descreva sua refeicao com detalhes',
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: _isListening ? 'Parar gravacao' : 'Iniciar gravacao',
                  button: true,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _isListening
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: _isListening
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.error,
                    ),
                    iconSize: 32,
                    onPressed: () => _toggleListening(vm),
                    icon: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AudioRecordingIndicator(
                  isRecording: _isListening,
                  secondsLeft: _segundosRestantes,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Text('Entrada por audio:'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isListening)
                      Text(
                        'Gravando... ${_segundosRestantes}s',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (estimate != null)
                  ConfidenceWarning(confidence: estimate.confidence),
                MealForm(
                  descricao: _descricao,
                  calorias: _calorias,
                  onDescricaoChanged: (v) => setState(() => _descricao = v),
                  onCaloriasChanged: (v) => setState(() => _calorias = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (estimate?.observacao != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'IA: ${estimate!.observacao}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (vm.estimateErrorMessage != null &&
                    vm.estimateErrorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Semantics(
                      label: 'Aviso de erro da estimativa',
                      liveRegion: true,
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.xs,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  vm.estimateErrorMessage!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fechar aviso',
                                onPressed: vm.clearEstimateError,
                                icon: const Icon(Icons.close_rounded),
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: vm.isLoading ? null : () => _estimar(vm),
                  icon: vm.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Estimar com IA'),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed:
                      _calorias > 0 ? () => _revisarEConfirmar(vm) : null,
                  child: const Text('Revisar e confirmar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

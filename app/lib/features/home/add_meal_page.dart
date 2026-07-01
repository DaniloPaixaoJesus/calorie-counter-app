import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/audio_transcription/audio_transcription_adapter.dart';
import 'package:calorie_counter_app/services/audio_transcription/offline_audio_transcription_adapter.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'widgets/meal_form.dart';
import 'widgets/confidence_warning.dart';
import 'widgets/audio_recording_indicator.dart';
import 'widgets/section_header.dart';
import 'widgets/ad_card.dart';
import 'package:calorie_counter_app/features/onboarding/paywall_page.dart';
import 'review_estimate_page.dart';
import 'view_model.dart';
import 'dart:async';

class AddMealPage extends StatefulWidget {
  final bool startWithAudio;
  final bool showAds;
  final VoidCallback? onMealSaved;

  const AddMealPage({
    super.key,
    this.startWithAudio = false,
    this.showAds = true,
    this.onMealSaved,
  });

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
  Macronutrients? _macronutrients;
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

  Future<void> _showDailyLimitDialog(HomeViewModel vm) async {
    vm.dismissDailyLimitDialog();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limite diário atingido'),
        content: const Text(
          'Você utilizou suas 3 estimativas gratuitas hoje.\n\n'
          'Volte amanhã ou assine o Premium para estimativas ilimitadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                adaptivePageRoute(
                  context: context,
                  builder: (_) => const PaywallPage(),
                ),
              );
            },
            child: const Text('Conhecer Premium'),
          ),
        ],
      ),
    );
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
      setState(() {
        _calorias = vm.estimate!.calorias;
        _macronutrients = vm.estimate!.macronutrients;
      });
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
      macronutrients: _macronutrients,
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
      adaptivePageRoute(
        context: context,
        builder: (_) => ReviewEstimatePage(
          descricaoInterpretada: estimate.descricaoInterpretada,
          calorias: _calorias,
          confidence: estimate.confidence,
          observacao: estimate.observacao,
          iconKey: estimate.iconKey,
          macronutrients: estimate.macronutrients,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _descricao = result.descricao;
      _calorias = result.calorias;
      _macronutrients = result.macronutrients;
    });
    await _confirmar(vm);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final estimate = vm.estimate;
    final remainingEstimates = vm.remainingDailyEstimates;
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    if (vm.shouldShowDailyLimitDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDailyLimitDialog(vm);
      });
    }

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
                  label: _isListening ? 'Parar gravacao' : 'Gravar audio',
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isListening
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: _isListening
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _toggleListening(vm),
                    icon: const Icon(Icons.mic_rounded),
                    label: Text(_isListening ? 'Parar' : 'Gravar audio'),
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
                Row(
                  children: [
                    Icon(
                      vm.shouldWarnEstimateQuota
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: vm.shouldWarnEstimateQuota
                          ? const Color(0xFF7A4D00)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        vm.hasUnlimitedEstimates
                            ? 'Estimativas ilimitadas'
                            : remainingEstimates == 0
                                ? 'Limite diário de estimativas atingido.'
                                : '$remainingEstimates estimativas restantes hoje',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: vm.shouldWarnEstimateQuota
                                  ? const Color(0xFF7A4D00)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
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
                  onPressed: vm.isLoading || !vm.canRequestEstimate
                      ? null
                      : () => _estimar(vm),
                  icon: vm.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Estimar com IA'),
                ),
                if (widget.showAds) ...[
                  const SizedBox(height: AppSpacing.md),
                  const AdCard(),
                ],
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

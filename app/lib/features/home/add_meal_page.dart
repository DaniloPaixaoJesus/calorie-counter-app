import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/models/meal.dart';
// import 'package:calorie_counter_app/services/speech/speech_service.dart';
import 'package:calorie_counter_app/services/audio_transcription/audio_transcription_adapter.dart';
import 'package:calorie_counter_app/services/audio_transcription/offline_audio_transcription_adapter.dart';
import 'widgets/meal_form.dart';
import 'widgets/confidence_warning.dart';
import 'view_model.dart';
import 'dart:async';

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

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

  void _confirmar(HomeViewModel vm) {
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
      nota: vm.estimate?.nota,
    );
    vm.addMeal(meal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final estimate = vm.estimate;

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Refeição')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entrada por áudio
            Row(
              children: [
                const Text('Entrada por áudio:'),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  color: _isListening ? Colors.red : null,
                  tooltip: _isListening ? 'Parar gravação' : 'Gravar áudio',
                  onPressed: () => _toggleListening(vm),
                ),
                if (_isListening)
                  Text(
                    'Gravando... ${_segundosRestantes}s',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Aviso de baixa confiança
            if (estimate != null)
              ConfidenceWarning(confidence: estimate.confidence),
            // Formulário
            MealForm(
              descricao: _descricao,
              calorias: _calorias,
              onDescricaoChanged: (v) => setState(() => _descricao = v),
              onCaloriasChanged: (v) => setState(() => _calorias = v),
            ),
            const SizedBox(height: 16),
            // Nota da IA
            if (estimate?.nota != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'IA: ${estimate!.nota}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),
            // Erro
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            // Botões
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
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _calorias > 0 ? () => _confirmar(vm) : null,
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

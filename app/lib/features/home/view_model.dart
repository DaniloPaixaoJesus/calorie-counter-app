import 'package:flutter/foundation.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/design_system/icon_key_registry.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
import 'package:calorie_counter_app/services/estimate_quota/estimate_quota_repository.dart';
import 'package:calorie_counter_app/services/estimate_quota/in_memory_estimate_quota_repository.dart';
import 'package:calorie_counter_app/services/repository/meal_repository.dart';
import 'package:calorie_counter_app/utils/datetime_extensions.dart';

class HomeViewModel extends ChangeNotifier {
  static const int dailyEstimateLimit = 30;

  final MealRepository _repository;
  final AiAdapter _aiAdapter;
  final EstimateQuotaRepository _estimateQuotaRepository;
  late DateTime dataSelecionada;

  HomeViewModel({
    required MealRepository repository,
    required AiAdapter aiAdapter,
    EstimateQuotaRepository? estimateQuotaRepository,
  })  : _repository = repository,
        _aiAdapter = aiAdapter,
        _estimateQuotaRepository =
            estimateQuotaRepository ?? InMemoryEstimateQuotaRepository() {
    // Initialize dataSelecionada to today (Feature 002)
    dataSelecionada = DateTime.now().toLocalDate();
  }

  // Feature 002: Date Navigation Getters
  bool get podeVoltar => true;

  bool get podeAvancar {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada.isBefore(hoje);
  }

  bool get eHoje {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada == hoje;
  }

  List<Meal> get meals => _repository.getAll();

  List<Meal> get mealsDoDia {
    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    return _repository
        .getAll()
        .where(
          (m) =>
              m.timestamp.year == yyyy &&
              m.timestamp.month == mm &&
              m.timestamp.day == dd,
        )
        .toList();
  }

  int get totalHoje => mealsDoDia.fold(0, (sum, meal) => sum + meal.calorias);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AiEstimate? _estimate;
  AiEstimate? get estimate => _estimate;

  /// Confiança abaixo de 0.7 dispara aviso ao usuário (FR-011).
  bool get lowConfidence => _estimate != null && _estimate!.confidence < 0.7;

  int get remainingDailyEstimates {
    final usedToday = _estimateQuotaRepository
        .getForDate(DateTime.now().toLocalDate())
        .usedCount;
    final remaining = dailyEstimateLimit - usedToday;
    return remaining < 0 ? 0 : remaining;
  }

  bool get canRequestEstimate => remainingDailyEstimates > 0;

  bool get shouldWarnEstimateQuota {
    final remaining = remainingDailyEstimates;
    return remaining > 0 && remaining <= 10;
  }

  String? _estimateErrorMessage;
  String? get estimateErrorMessage => _estimateErrorMessage;

  String? _homeErrorMessage;
  String? get homeErrorMessage => _homeErrorMessage;

  String? get errorMessage => _estimateErrorMessage ?? _homeErrorMessage;

  Future<void> requestEstimate(String descricao) async {
    if (!canRequestEstimate) {
      _estimateErrorMessage =
          'Limite diário de estimativas atingido. Tente novamente amanhã.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _estimateErrorMessage = null;
    _estimate = null;
    await _estimateQuotaRepository.increment(DateTime.now().toLocalDate());
    notifyListeners();

    try {
      final raw = await _aiAdapter.estimateCalories(descricao);
      _estimate = AiEstimate(
        descricaoInterpretada: raw.descricaoInterpretada,
        calorias: raw.calorias,
        observacao: raw.observacao,
        confidence: raw.confidence,
        iconKey: IconKeyRegistry.normalize(raw.iconKey),
      );
    } on AiAdapterException catch (e) {
      _estimateErrorMessage = e.statusCode == null
          ? e.message
          : 'HTTP ${e.statusCode} - ${e.message}';
    } catch (_) {
      _estimateErrorMessage = 'Erro inesperado ao estimar calorias.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(Meal meal) async {
    await _repository.add(meal);
    _estimate = null;
    _estimateErrorMessage = null;
    _homeErrorMessage = null;
    notifyListeners();
  }

  Future<void> updateMeal(Meal meal) async {
    await _repository.update(meal);
    _homeErrorMessage = null;
    notifyListeners();
  }

  Future<void> removeMeal(String id) async {
    await _repository.remove(id);
    notifyListeners();
  }

  void clearEstimate() {
    _estimate = null;
    _estimateErrorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _estimateErrorMessage = null;
    _homeErrorMessage = null;
    notifyListeners();
  }

  void clearEstimateError() {
    _estimateErrorMessage = null;
    notifyListeners();
  }

  void clearHomeError() {
    _homeErrorMessage = null;
    notifyListeners();
  }

  // Feature 002: Date Navigation Methods
  void voltarDia() {
    dataSelecionada = dataSelecionada.subtract(Duration(days: 1));
    notifyListeners();
  }

  void avancarDia() {
    if (podeAvancar) {
      dataSelecionada = dataSelecionada.add(Duration(days: 1));
      notifyListeners();
    }
  }

  void voltarParaHoje() {
    dataSelecionada = DateTime.now().toLocalDate();
    notifyListeners();
  }

  // Feature 002: Meal Removal Methods
  Meal? getMealById(String id) {
    try {
      return _repository.getAll().firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> confirmarRemocao(String mealId) async {
    final meal = getMealById(mealId);
    if (meal == null) {
      _homeErrorMessage = 'Refeição não encontrada';
      notifyListeners();
      return;
    }

    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    if (!(meal.timestamp.year == yyyy &&
        meal.timestamp.month == mm &&
        meal.timestamp.day == dd)) {
      _homeErrorMessage = 'Refeição não pertence à data selecionada';
      notifyListeners();
      return;
    }

    await _repository.remove(mealId);
    _homeErrorMessage = null;
    notifyListeners();
  }

  void cancelarRemocao() {
    // No-op; dialog fechado pelo widget
  }
}

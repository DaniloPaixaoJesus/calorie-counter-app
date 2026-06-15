import 'package:flutter/foundation.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final InMemoryRepository _repository;
  final AiAdapter _aiAdapter;

  HomeViewModel({
    required InMemoryRepository repository,
    required AiAdapter aiAdapter,
  }) : _repository = repository,
       _aiAdapter = aiAdapter;
  List<Meal> get meals => _repository.getAll();
  int get totalHoje => _repository.getTotalCaloriesHoje();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AiEstimate? _estimate;
  AiEstimate? get estimate => _estimate;

  /// Confiança abaixo de 0.7 dispara aviso ao usuário (FR-011).
  bool get lowConfidence => _estimate != null && _estimate!.confidence < 0.7;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> requestEstimate(String descricao) async {
    _isLoading = true;
    _errorMessage = null;
    _estimate = null;
    notifyListeners();

    try {
      _estimate = await _aiAdapter.estimateCalories(descricao);
    } on AiAdapterException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao estimar calorias.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addMeal(Meal meal) {
    _repository.add(meal);
    _estimate = null;
    _errorMessage = null;
    notifyListeners();
  }

  void removeMeal(String id) {
    _repository.remove(id);
    notifyListeners();
  }

  void clearEstimate() {
    _estimate = null;
    _errorMessage = null;
    notifyListeners();
  }
}

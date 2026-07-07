import 'dart:convert';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/bff_client.dart';

class UserBffException implements Exception {
  final String message;
  final int? statusCode;

  const UserBffException(this.message, {this.statusCode});

  @override
  String toString() => 'UserBffException: $message';
}

class UserBffService {
  final BffClient client;
  final String Function() localeProvider;

  UserBffService({
    BffClient? client,
    required this.localeProvider,
  }) : client = client ?? BffClient();

  Future<AppSettings> authenticateGoogle(GoogleAuthAccount account) async {
    final response = await client.post('/auth/google', {
      'email': account.email,
      'name': account.displayName,
      'photoUrl': account.photoUrl,
      'idToken': account.idToken,
      'accessToken': account.accessToken,
      'locale': localeProvider(),
    });

    return _settingsFromResponse(response).copyWith(
      googleAuthToken: account.idToken ?? account.accessToken,
    );
  }

  Future<AppSettings> updateProfile(AppSettings settings) async {
    final userId = settings.userId;
    if (userId == null || userId.isEmpty) {
      throw const UserBffException('Usuário sem id remoto');
    }

    final response = await client.put(
      '/users/$userId',
      {
        'name': settings.userName,
        'birthDate': settings.birthDate?.toIso8601String().split('T').first,
        'gender': settings.gender,
        'dailyCalorieGoal': settings.dailyCalorieGoal,
        'locale': localeProvider(),
      },
      bearerToken: settings.googleAuthToken,
    );

    return _settingsFromResponse(response).copyWith(
      googleAuthToken: settings.googleAuthToken,
    );
  }

  Future<List<Meal>> listMeals({
    required String userId,
    required String? bearerToken,
  }) async {
    final response = await client.get(
      '/users/$userId/meals',
      bearerToken: bearerToken,
    );

    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const UserBffException('Resposta inválida do BFF');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_mealFromResponse)
        .toList();
  }

  Future<void> addMeal({
    required String userId,
    required Meal meal,
    required String? bearerToken,
  }) async {
    final response = await client.post(
      '/users/$userId/meals',
      {
        'id': meal.id,
        'descricao': meal.descricao,
        'descricaoOriginal': meal.descricaoOriginal,
        'calorias': meal.calorias,
        'timestamp': meal.timestamp.toUtc().toIso8601String(),
        'origem': meal.origem.name,
        'aiConfidence': meal.aiConfidence,
        'nota': meal.nota,
        'iconKey': meal.iconKey,
        'macronutrients': {
          'proteinGrams': meal.macronutrients?.protein.grams ?? 0,
          'carbohydrateGrams': meal.macronutrients?.carbs.grams ?? 0,
          'fatGrams': meal.macronutrients?.fat.grams ?? 0,
        },
      },
      bearerToken: bearerToken,
    );

    _ensureSuccess(response);
  }

  AppSettings _settingsFromResponse(BffResponse response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const UserBffException('Resposta inválida do BFF');
    }

    return AppSettings(
      selectedPlan: AppPlan.premium,
      isPremium: decoded['premium'] == true,
      userLogged: true,
      userId: _readString(decoded, 'id'),
      userEmail: _readString(decoded, 'email'),
      userName: _readString(decoded, 'name'),
      userPhotoAssetPath: _readString(decoded, 'photoUrl'),
      googleAuthToken: null,
      trialStartDate: _parseDate(_readString(decoded, 'createdAt')),
      birthDate: _parseDate(_readString(decoded, 'birthDate')),
      gender: _readString(decoded, 'gender'),
      dailyCalorieGoal: _readInt(decoded, 'dailyCalorieGoal') ?? 2000,
      remainingDailyEstimations: 3,
      lastResetDate: DateTime.now(),
    );
  }

  Meal _mealFromResponse(Map<String, dynamic> json) {
    final macros = json['macronutrients'];
    final macrosJson = macros is Map<String, dynamic> ? macros : null;
    return Meal(
      id: _readString(json, 'id') ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      descricao: _readString(json, 'descricao') ?? '',
      descricaoOriginal: _readString(json, 'descricaoOriginal'),
      calorias: _readInt(json, 'calorias') ?? 0,
      timestamp: DateTime.tryParse(_readString(json, 'timestamp') ?? '') ??
          DateTime.now(),
      origem: _parseOrigem(_readString(json, 'origem')),
      aiConfidence: _readDouble(json, 'aiConfidence'),
      nota: _readString(json, 'nota'),
      iconKey: _readString(json, 'iconKey') ?? 'default',
      macronutrients: macrosJson == null
          ? null
          : Macronutrients.fromGramValues(
              proteinGrams: _readInt(macrosJson, 'proteinGrams') ?? 0,
              carbohydrateGrams: _readInt(macrosJson, 'carbohydrateGrams') ?? 0,
              fatGrams: _readInt(macrosJson, 'fatGrams') ?? 0,
            ),
    );
  }

  void _ensureSuccess(BffResponse response) {
    if (response.isSuccess) return;
    throw UserBffException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(BffResponse response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return _readString(decoded, 'mensagem') ??
            _readString(decoded, 'message') ??
            'Falha ao chamar BFF';
      }
    } on FormatException {
      if (response.body.trim().isNotEmpty) return response.body.trim();
    }
    return 'Falha ao chamar BFF';
  }

  String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }

  MealOrigem _parseOrigem(String? value) {
    for (final origem in MealOrigem.values) {
      if (origem.name == value) return origem;
    }
    return MealOrigem.texto;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

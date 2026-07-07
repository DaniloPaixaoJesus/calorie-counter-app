enum AppPlan {
  free,
  premium,
}

class AppSettings {
  final AppPlan? selectedPlan;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final bool isPremium;
  final int remainingDailyEstimations;
  final DateTime? lastResetDate;
  final bool userLogged;
  final String? userName;
  final String? userEmail;
  final String? userPhotoAssetPath;
  final int dailyCalorieGoal;

  const AppSettings({
    this.selectedPlan,
    this.trialStartDate,
    this.trialEndDate,
    this.isPremium = false,
    this.remainingDailyEstimations = 3,
    this.lastResetDate,
    this.userLogged = false,
    this.userName,
    this.userEmail,
    this.userPhotoAssetPath,
    this.dailyCalorieGoal = 2000,
  });

  static const empty = AppSettings();

  bool get hasSelectedPlan => selectedPlan != null;

  AppSettings copyWith({
    AppPlan? selectedPlan,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? isPremium,
    int? remainingDailyEstimations,
    DateTime? lastResetDate,
    bool? userLogged,
    String? userName,
    String? userEmail,
    String? userPhotoAssetPath,
    int? dailyCalorieGoal,
  }) {
    return AppSettings(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      isPremium: isPremium ?? this.isPremium,
      remainingDailyEstimations:
          remainingDailyEstimations ?? this.remainingDailyEstimations,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      userLogged: userLogged ?? this.userLogged,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoAssetPath: userPhotoAssetPath ?? this.userPhotoAssetPath,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'selectedPlan': selectedPlan?.name,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'isPremium': isPremium ? 1 : 0,
      'remainingDailyEstimations': remainingDailyEstimations,
      'lastResetDate': lastResetDate?.toIso8601String(),
      'userLogged': userLogged ? 1 : 0,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoAssetPath': userPhotoAssetPath,
      'dailyCalorieGoal': dailyCalorieGoal,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      selectedPlan: _parsePlan(map['selectedPlan']),
      trialStartDate: _parseDate(map['trialStartDate']),
      trialEndDate: _parseDate(map['trialEndDate']),
      isPremium: map['isPremium'] == 1,
      remainingDailyEstimations:
          (map['remainingDailyEstimations'] as int?) ?? 3,
      lastResetDate: _parseDate(map['lastResetDate']),
      userLogged: map['userLogged'] == 1,
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      userPhotoAssetPath: map['userPhotoAssetPath'] as String?,
      dailyCalorieGoal: (map['dailyCalorieGoal'] as int?) ?? 2000,
    );
  }

  static AppPlan? _parsePlan(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final plan in AppPlan.values) {
      if (plan.name == value) return plan;
    }
    return null;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

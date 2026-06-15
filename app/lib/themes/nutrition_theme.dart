import 'package:flutter/material.dart';

/// Tema Material 3 para o Calorie Counter.
/// Seed: #2E7D32 (verde) — paleta nutrição/saúde.
class NutritionTheme {
  NutritionTheme._();

  static const Color _seed = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFFFFA726);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color background = Color(0xFFFFFDF6);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      secondary: secondary,
      surface: background,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  /// Variante de alto contraste (fundo escuro).
  static ThemeData get highContrast {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}

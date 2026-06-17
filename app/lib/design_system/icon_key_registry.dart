class IconKeyRegistry {
  IconKeyRegistry._();

  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snack = 'snack';
  static const String drink = 'drink';
  static const String dessert = 'dessert';
  static const String defaultKey = 'default';

  static const Set<String> supported = {
    breakfast,
    lunch,
    dinner,
    snack,
    drink,
    dessert,
    defaultKey,
  };

  static String normalize(String? key) {
    if (key == null) return defaultKey;
    final normalized = key.trim().toLowerCase();
    if (supported.contains(normalized)) return normalized;
    return defaultKey;
  }
}

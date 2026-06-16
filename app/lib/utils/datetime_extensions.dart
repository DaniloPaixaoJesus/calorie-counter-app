/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Retorna uma nova DateTime com apenas a data (ano, mês, dia), sem hora.
  /// Útil para comparações de data ignorando a hora.
  DateTime toLocalDate() {
    return DateTime(year, month, day);
  }
}

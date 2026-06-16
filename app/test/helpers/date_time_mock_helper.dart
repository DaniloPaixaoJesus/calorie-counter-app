
/// Helper para mockar DateTime.now() em testes de navegação de data
/// Permite testar lógica de datas sem depender da data real do sistema
class DateTimeMockHelper {
  static late DateTime _mockDate;

  /// Define uma data mockada para uso em testes
  static void setMockDate(DateTime date) {
    _mockDate = date;
  }

  /// Retorna a data mockada (ou a data real se não foi setada)
  static DateTime getMockDate() {
    return _mockDate;
  }

  /// Reseta o mock para a data real
  static void reset() {
    _mockDate = DateTime.now();
  }
}

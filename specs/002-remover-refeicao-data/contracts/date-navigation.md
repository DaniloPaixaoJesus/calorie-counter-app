# Contract: Date Navigation Interface

**Version**: 1.0 | **Generated**: 2026-06-15 | **For**: Feature 002

## Public Interface

### HomeViewModel Extensions (Date Navigation)

```dart
class HomeViewModel extends ChangeNotifier {
  // État
  DateTime dataSelecionada = DateTime.now();

  // Computed Properties
  bool get podeVoltar => true; // sempre permite voltar

  bool get podeAvancar {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada.toLocalDate().isBefore(hoje);
  }

  bool get eHoje {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada.toLocalDate() == hoje;
  }

  // Filtered Meals by Date
  List<Meal> get mealsDoDia {
    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    return _meals
        .where((m) => m.timestamp.year == yyyy && 
                      m.timestamp.month == mm && 
                      m.timestamp.day == dd)
        .toList();
  }

  // Total Calories for Selected Date
  int get totalHoje {
    return mealsDoDia.fold(0, (sum, meal) => sum + meal.calorias);
  }

  // Actions
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
}
```

## Expected Behavior

### voltarDia()

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Voltar de 15 de junho | dataSelecionada = 15 jun | dataSelecionada = 14 jun | Sem limite inferior |
| Voltar de 1º de janeiro | dataSelecionada = 1º jan | dataSelecionada = 31 dez (ano anterior) | Suporta ano anterior |

### avancarDia()

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Avançar de 14 de junho (hoje = 15 jun) | dataSelecionada = 14 jun | dataSelecionada = 15 jun | Permite até hoje |
| Tentar avançar em hoje (hoje = 15 jun) | dataSelecionada = 15 jun | dataSelecionada = 15 jun (inalterado) | Silenciosamente ignora; botão UI desabilitado |

### voltarParaHoje()

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Voltar para hoje (hoje = 15 jun) | dataSelecionada = 10 jun | dataSelecionada = 15 jun | Sempre reseta para hoje |

### mealsDoDia

| Scenario | Meals | dataSelecionada | Expected | Notes |
|----------|-------|-----------------|----------|-------|
| Refeições hoje | [15 jun 8h, 15 jun 12h, 14 jun 19h] | 15 jun | [15 jun 8h, 15 jun 12h] | Filtra por data, ignora hora |
| Sem refeições | [] | 15 jun | [] | Empty list |
| Refeições em múltiplos dias | [14 jun, 15 jun, 16 jun] | 15 jun | [15 jun refeição] | Apenas 1 dia selecionado |

## Formatting Contract

### Data Display (HomePage)

```dart
import 'package:intl/intl.dart';

// Formato: "seg, 15 de junho"
final formatter = DateFormat('EEEE, d de MMMM', 'pt_BR');
String dataExibida = formatter.format(dataSelecionada);
```

### Navigation Button States

```dart
// Anterior: sempre habilitado
ElevatedButton(
  onPressed: () => vm.voltarDia(),
  child: Text('< Anterior'),
)

// Próximo: desabilitado em hoje
ElevatedButton(
  onPressed: vm.podeAvancar ? () => vm.avancarDia() : null,
  child: Text('> Próximo'),
)

// Hoje: destaque visual se não está em hoje
OutlinedButton(
  onPressed: vm.eHoje ? null : () => vm.voltarParaHoje(),
  child: Text('Hoje'),
)
```

## Error Handling

Nenhuma exceção esperada em operações normais. Validação preventiva:

- `voltarDia()`: sem limite, sempre executa.
- `avancarDia()`: validação silenciosa; botão UI desabilitado quando `!podeAvancar`.
- `voltarParaHoje()`: sempre executa.

---

**Status**: COMPLETE — contrato de navegação de datas definido.

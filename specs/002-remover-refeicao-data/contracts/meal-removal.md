# Contract: Meal Removal Interface

**Version**: 1.0 | **Generated**: 2026-06-15 | **For**: Feature 002

## Public Interface

### HomeViewModel Extensions (Meal Removal)

```dart
class HomeViewModel extends ChangeNotifier {
  // Existing properties...
  String? _pendingRemovalId; // para tracking de diálogo pendente

  // Query
  Meal? getMealById(String id) {
    try {
      return _meals.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // Action: Initiate Removal (shows confirmation dialog)
  Future<bool?> solicitarRemocao(String mealId) async {
    _pendingRemovalId = mealId;
    // Dialog será exibido pelo widget; retorna true se confirmado
    // Implementação ocorre no widget (HomePage)
    return null; // placeholder; implementação UI
  }

  // Action: Confirm Removal
  void confirmarRemocao(String mealId) {
    final meal = getMealById(mealId);
    if (meal == null) {
      errorMessage = 'Refeição não encontrada';
      notifyListeners();
      return;
    }

    // Validação: refeição deve pertencer ao dia selecionado
    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    if (!(meal.timestamp.year == yyyy &&
          meal.timestamp.month == mm &&
          meal.timestamp.day == dd)) {
      errorMessage = 'Refeição não pertence à data selecionada';
      notifyListeners();
      return;
    }

    // Remove
    _repository.remove(mealId);
    _meals = _repository.getAll();
    errorMessage = null;
    _pendingRemovalId = null;
    notifyListeners();
  }

  // Action: Cancel Removal
  void cancelarRemocao() {
    _pendingRemovalId = null;
    // Sem notificação; apenas reseta estado
  }
}
```

## Expected Behavior

### solicitarRemocao(String mealId)

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Remover refeição existente | mealId = "abc123" | Dialog exibido com confirmação | Refeição deve estar na data selecionada |
| Remover refeição inexistente | mealId = "xyz999" | errorMessage = 'Refeição não encontrada' | Sem dialog |
| Remover refeição de outro dia | mealId = "xyz" (de 14 jun), dataSelecionada = 15 jun | errorMessage = 'Refeição não pertence à data selecionada' | Proteção contra remoção em data errada |

### confirmarRemocao(String mealId)

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Confirmar remoção | mealId = "abc123" | Refeição removida, total recalculado | totalHoje reduz de calorias_refeicao |
| Remover última refeição do dia | mealId = única | mealsDoDia fica vazio, estaVazio = true | UI mostra estado vazio |
| Remoção em data não-hoje | mealId = de 14 jun, dataSelecionada = 14 jun | Removida, apenas total de 14 jun afetado | Data 15 jun permanece inalterada |

### cancelarRemocao()

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Cancelar confirmação | Dialog aberto | Dialog fecha, lista inalterada | Estado anterior preservado |

## Dialog Behavior (UI Contract)

### Confirmation Dialog

```dart
// Em HomePage widget
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Remover refeição?'),
    content: Text('Esta ação não pode ser desfeita.'),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          vm.cancelarRemocao();
        },
        child: Text('Cancelar'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          vm.confirmarRemocao(mealId);
        },
        child: Text('Remover'),
      ),
    ],
  ),
);
```

### Trigger Points

- **Long-press em item de refeição**: Mostra dialog de confirmação.
- **Ícone de deletar em item de refeição**: Alternativa ao long-press.

## Data Isolation Contract

**Garantia**: Remoção de refeição em uma data NUNCA afeta outra data.

```dart
// Exemplo de validação
void confirmarRemocao(String mealId) {
  final meal = getMealById(mealId);
  
  // INVARIANTE: validar que refeição é do dia selecionado
  assert(
    meal.timestamp.year == dataSelecionada.year &&
    meal.timestamp.month == dataSelecionada.month &&
    meal.timestamp.day == dataSelecionada.day,
    'Remoção fora de escopo: refeição de outro dia'
  );

  // Remove
  _repository.remove(mealId);
  
  // Verificação: dados de outras datas preservados
  // (testado em testes de integração)
}
```

## Error Handling

| Error | Cause | Action |
|-------|-------|--------|
| Refeição não encontrada | mealId inválido | Exibe `errorMessage`; sem dialog |
| Refeição de outro dia | dataSelecionada mismatch | Rejeita silenciosamente com error |
| Repository error | Falha ao remover | Exibe `errorMessage`; mantém estado anterior |

---

**Status**: COMPLETE — contrato de remoção de refeição definido.

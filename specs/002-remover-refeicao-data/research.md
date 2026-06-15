# Research: Remover refeição e navegar por data

**Generated**: 2026-06-15 | **For**: Feature 002 | **Status**: Complete

## Decisões Técnicas Resolvidas

### RES-001: Formatação de Data em Português

**Pesquisa**: Como exibir data em português ("seg, 15 de junho") em Flutter?

**Decisão**: Usar package `intl` (já é dependência padrão de Flutter).

**Implementação**:
```dart
import 'package:intl/intl.dart';

final dateFormatter = DateFormat('EEEE, d de MMMM', 'pt_BR');
String dataFormatada = dateFormatter.format(dataSelecionada);
// Output: "segunda-feira, 15 de junho"
```

**Rationale**:
- `intl` é padrão em Flutter; não adiciona dependência nova.
- Suporta localização automática com `'pt_BR'`.
- Simplifica exibição de data no widget.

**Status**: RESOLVIDO ✓

---

### RES-002: Comparação de Data sem Hora (toLocalDate equivalente)

**Pesquisa**: Qual é a forma idiomática em Dart para comparar datas ignorando hora?

**Decisão**: Criar helper extension `toLocalDate()` em `DateTime`.

**Implementação**:
```dart
// Em um arquivo utils/datetime_extensions.dart
extension DateTimeExtensions on DateTime {
  DateTime toLocalDate() {
    return DateTime(year, month, day);
  }
}

// Uso:
final hoje = DateTime.now().toLocalDate();
final mesmaData = DateTime(2026, 6, 15, 14, 30).toLocalDate();
assert(hoje == hoje); // true
```

**Rationale**:
- Clareza semântica (método `.toLocalDate()` deixa claro a intenção).
- Reutilizável em toda a codebase.
- Evita repetir `DateTime(y, m, d)` múltiplas vezes.

**Status**: RESOLVIDO ✓

---

### RES-003: UX de Estado Vazio por Data

**Pesquisa**: Como exibir mensagem clara quando uma data não tiver refeições?

**Decisão**: Reutilizar widget `EmptyStateWidget` da feature 001, parametrizar com data.

**Implementação**:
```dart
// Em features/home/widgets/empty_state.dart
class EmptyStateWidget extends StatelessWidget {
  final DateTime data;

  const EmptyStateWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('d de MMMM', 'pt_BR').format(data);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restaurant_menu_outlined, size: 64),
        SizedBox(height: 16),
        Text('Nenhuma refeição em $dataFormatada'),
      ],
    );
  }
}

// Uso em HomePage:
if (mealsDoDia.isEmpty) {
  EmptyStateWidget(data: dataSelecionada)
}
```

**Rationale**:
- Mensagem contextualizada por data melhora clareza para usuário.
- Reutiliza estrutura de widget existente.
- Compatível com Material 3 design da feature 001.

**Status**: RESOLVIDO ✓

---

### RES-004: Sincronismo de Timestamp ao Adicionar em Data Não-Hoje

**Pesquisa**: Como garantir que refeição adiciona em data não-hoje fica vinculada a essa data?

**Decisão**: Ajustar `timestamp` no factory `Meal.create()` para (dataSelecionada) + (hora local agora).

**Implementação**:
```dart
// Em models/meal.dart
factory Meal.create({
  required String descricao,
  required int calorias,
  required MealOrigem origem,
  required DateTime dataSelecionada, // NOVO parâmetro
  double? aiConfidence,
  String? nota,
}) {
  final agora = DateTime.now();
  final timestampAjustado = DateTime(
    dataSelecionada.year,
    dataSelecionada.month,
    dataSelecionada.day,
    agora.hour,
    agora.minute,
    agora.second,
  );
  
  assert(descricao.isNotEmpty, 'descricao não pode estar vazia');
  assert(calorias >= 0, 'calorias não pode ser negativo');
  
  return Meal(
    id: const Uuid().v4(),
    descricao: descricao,
    calorias: calorias,
    timestamp: timestampAjustado,
    origem: origem,
    aiConfidence: aiConfidence,
    nota: nota,
  );
}
```

**Rationale**:
- Garante que cada refeição fica vinculada ao dia selecionado sem necessidade de campo separado.
- Preserva hora local para futuras análises de timing.
- Compatível com critério SC-003 (remoção em data não-hoje não afeta outras datas).

**Status**: RESOLVIDO ✓

---

## Dependências Confirmadas

- `intl` — para formatação de data localizada.
- Nenhuma dependência nova necessária; feature 001 já fornece `uuid`, `provider`, Flutter padrão.

## Próximas Ações

- Incorporar insights de data-model.md e contracts/ (Phase 1).
- Proceder com decomposição de tasks após Phase 1 validação.

**Status**: COMPLETE — todas as ambiguidades técnicas resolvidas.

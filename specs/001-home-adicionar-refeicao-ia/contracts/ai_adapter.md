# Contrato: AiAdapter

**Feature**: 001-home-adicionar-refeicao-ia  
**Criado**: 2026-06-15  
**Status**: Definido

## Visão Geral

`AiAdapter` é a interface que desacopla a camada de apresentação/domínio de qualquer implementação de IA. No MVP, a implementação é `AiAdapterMock`. A interface DEVE ser substituível sem alteração nos widgets ou na lógica de domínio.

## Interface Dart

```dart
// app/lib/services/ai_adapter/ai_adapter.dart

abstract class AiAdapter {
  /// Estima as calorias de uma refeição descrita em texto livre.
  ///
  /// Lança [AiAdapterException] em caso de falha irrecuperável.
  /// Retorna [AiEstimate] com todos os campos presentes.
  Future<AiEstimate> estimateCalories(String descricao);
}

class AiEstimate {
  final String descricaoInterpretada; // texto reescrito/normalizado pela IA
  final int calorias;                  // estimativa em kcal (inteiro)
  final String? nota;                  // observação curta opcional (ex: "porção estimada")
  final double confidence;             // 0.0 a 1.0 (1.0 = máxima confiança)

  const AiEstimate({
    required this.descricaoInterpretada,
    required this.calorias,
    this.nota,
    required this.confidence,
  });
}

class AiAdapterException implements Exception {
  final String message;
  const AiAdapterException(this.message);
}
```

## Entrada

| Campo       | Tipo     | Restrições                                     |
|-------------|----------|------------------------------------------------|
| `descricao` | `String` | Não vazio, mínimo 2 caracteres, máximo 1.000   |

## Saída (`AiEstimate`)

| Campo                   | Tipo      | Obrigatório | Regras                                              |
|-------------------------|-----------|-------------|-----------------------------------------------------|
| `descricaoInterpretada` | `String`  | Sim         | Não vazio; pode diferir da entrada                 |
| `calorias`              | `int`     | Sim         | >= 0; zero indica incapacidade de estimar          |
| `nota`                  | `String?` | Não         | Máximo 140 caracteres                               |
| `confidence`            | `double`  | Sim         | 0.0 a 1.0 inclusive                                |

## Erros

| Condição                          | Comportamento esperado                               |
|-----------------------------------|------------------------------------------------------|
| `descricao` vazia ou muito curta  | Lançar `AiAdapterException` antes de chamar adapter |
| Timeout (API externa futura)      | Lançar `AiAdapterException('timeout')`              |
| Resposta inválida                 | Lançar `AiAdapterException('resposta inválida')`    |

## Threshold de Confiança

- `confidence >= 0.7` → exibir normalmente
- `confidence < 0.7` → exibir aviso e destacar campos editáveis para revisão
- `calorias == 0` → forçar edição manual pelo usuário antes de salvar

## Implementação Mock (MVP)

Localização: `app/lib/services/ai_adapter/ai_adapter_mock.dart`

Comportamento:
- Mapeia palavras-chave comuns (ex: "arroz", "feijão", "frango") para estimativas fixas.
- Retorna `confidence: 0.9` para entradas reconhecidas, `0.5` para entradas desconhecidas.
- Retorna `calorias: 0` e `confidence: 0.3` quando não há palavras-chave reconhecíveis.
- Delay simulado: `await Future.delayed(Duration(milliseconds: 300))`.

## Localização no Monorepo

```
app/lib/services/ai_adapter/
├── ai_adapter.dart        # interface (abstrato)
└── ai_adapter_mock.dart   # implementação MVP
```

## Exemplo de Uso

```dart
final AiAdapter adapter = AiAdapterMock();
final estimate = await adapter.estimateCalories('2 colheres de arroz e frango grelhado');
print(estimate.calorias);      // ex: 380
print(estimate.confidence);    // ex: 0.9
```

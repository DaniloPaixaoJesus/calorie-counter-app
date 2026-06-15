# Data Model: Meal (Refeição)

**Entity**: Meal

- `id`: string (uuid)
- `descricao`: string — descrição completa informada/interpretada
- `calorias`: integer — valor estimado/ajustado pelo usuário
- `timestamp`: ISO-8601 datetime
- `origem`: enum(`texto`, `audio`)
- `ai_confidence`: number (0..1) opcional
- `nota`: string opcional (observação curta da IA)

## Validation Rules

- `descricao` DEVE ser não vazia.
- `calorias` DEVE ser inteiro não-negativo.
- `timestamp` DEVE refletir a data/hora do registro; na ausência de especificação, usar o horário atual.

## Example JSON

```json
{
  "id": "uuid-1234",
  "descricao": "arroz, feijão, frango grelhado e salada",
  "calorias": 650,
  "timestamp": "2026-06-15T12:34:00Z",
  "origem": "texto",
  "ai_confidence": 0.92,
  "nota": "Estimativa baseada em porções médias"
}
```


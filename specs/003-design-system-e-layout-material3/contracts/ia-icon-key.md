# Contrato: Retorno da IA com iconKey

## Objetivo

Definir o payload de estimativa para suportar ícone, calorias e observação.

## Payload esperado

```json
{
  "descricaoInterpretada": "Arroz, feijão, frango grelhado e salada",
  "calorias": 650,
  "confidence": 0.85,
  "observacao": "Quantidade não informada; assumida porção média de 100g",
  "iconKey": "lunch"
}
```

## Regras

1. `calorias` é obrigatória e não-negativa.
2. `iconKey` é obrigatória no contrato lógico; quando ausente/inválida, o app deve normalizar para `default`.
3. O app aceita apenas:
   - `breakfast`, `lunch`, `dinner`, `snack`, `drink`, `dessert`, `default`.
4. Não há geração dinâmica de ícones.
5. A análise da IA para `iconKey` considera:
   - descrição da refeição;
   - alimentos identificados;
   - data/hora do registro.
6. O usuário revisa refeição antes de salvar, sem editar o ícone nesta feature.

## Critérios de conformidade

- Estimativa retorna `iconKey`.
- Refeição salva persiste `iconKey` normalizado.
- Lista exibe ícone correspondente.
- Retorno inválido ou ausente aplica `default`.
- Fluxo funciona para entrada texto e áudio.

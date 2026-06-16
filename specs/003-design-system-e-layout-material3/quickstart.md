# Quickstart: Design System e Layout Material 3

**Generated**: 2026-06-16 | **For**: Feature 003 | **Type**: Validation Guide

## Pré-requisitos

- Flutter e Dart instalados.
- Projeto configurado em `app/`.
- Feature 003 implementada conforme tarefas.

## Setup

```bash
cd app
flutter pub get
flutter run
```

## Cenário 1: Home com card de total e lista limpa

1. Abrir app na Home.
2. Verificar card de total de calorias com destaque visual.
3. Verificar lista de refeições com ícones e calorias.
4. Validar navegação inferior com `Home` e `Adicionar`.

## Cenário 2: Fluxo Adicionar (texto e áudio)

1. Acessar aba `Adicionar`.
2. Verificar opções de entrada por texto e áudio com cards consistentes.
3. Em áudio, validar indicador visual e timer regressivo.
4. Concluir e seguir para revisão.

## Cenário 3: Revisão de estimativa da IA

1. Conferir descrição interpretada, calorias, confiança e observação.
2. Verificar que ícone é definido pela IA (sem edição manual nesta feature).
3. Confirmar refeição e voltar para Home.

## Cenário 4: Fallback de iconKey

1. Simular retorno da IA com `iconKey` inválida/ausente.
2. Confirmar refeição.
3. Verificar que lista mostra ícone `default`.

## Cenário 5: Remoção com confirmação e estado vazio

1. Remover uma refeição e validar diálogo de confirmação.
2. Cancelar e confirmar para validar ambos comportamentos.
3. Com lista vazia, validar estado vazio amigável.

## Cenário 6: Responsividade

1. Testar em tela pequena e grande.
2. Verificar legibilidade, espaçamentos e áreas de toque.
3. Garantir que fluxo funcional não muda entre tamanhos.

## Validação de qualidade

```bash
cd app
dart format lib test
flutter analyze
flutter test
```

## Referências

- `contracts/design-system.md`
- `contracts/ia-icon-key.md`
- `contracts/responsive-layout.md`
- `data-model.md`

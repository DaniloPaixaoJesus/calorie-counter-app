# Contrato: Responsividade de Layout

## Objetivo

Definir comportamento visual consistente em telas pequenas e grandes sem alterar o fluxo funcional.

## Breakpoints

- **Pequena**: largura < 360dp
- **Base**: 360dp a 599dp
- **Grande**: >= 600dp

## Regras por breakpoint

1. **Pequena**
   - Reduzir paddings horizontais.
   - Priorizar quebra de texto em cards/listas.
   - Manter área de toque mínima de 48dp.

2. **Base**
   - Layout padrão mobile, card de total e lista em coluna única.

3. **Grande**
   - Conteúdo centralizado com largura máxima.
   - Espaçamento vertical maior para conforto visual.
   - Sem mudança no fluxo de passos (apenas apresentação).

## Acessibilidade

- Contraste adequado em tema claro.
- Textos com tamanho legível e suporte a scale factor.
- Elementos interativos com semântica para leitor de tela.

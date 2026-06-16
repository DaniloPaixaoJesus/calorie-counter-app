# Research: Design System e Layout Material 3

**Generated**: 2026-06-16 | **For**: Feature 003 | **Status**: Complete

## Decisões Técnicas

### DEC-001: Tema e tokens visuais em Material 3

**Decision**: Adotar tema claro Material 3 com tokens explícitos para cor, tipografia, espaçamento, borda e elevação, centralizados no módulo de tema.

**Rationale**:
- Garante consistência visual entre Home, fluxo de adicionar, revisão e diálogos.
- Evita estilos hardcoded espalhados em widgets.
- Permite evolução incremental do design sem reescrever telas.

**Alternatives considered**:
- Manter estilos locais por tela (rejeitado por baixa consistência).
- Criar design system externo completo (rejeitado por complexidade para MVP).

---

### DEC-002: Card de total de calorias como componente de destaque

**Decision**: Definir um componente reutilizável para o card de total com destaque em verde e tipografia grande para valor calórico.

**Rationale**:
- Atende a referência visual sem copiar layout literalmente.
- Reforça hierarquia de informação da Home.
- Reduz duplicação de layout em variações de estado da Home.

**Alternatives considered**:
- Usar `Container` inline na Home (rejeitado por dificultar padronização).

---

### DEC-003: Contrato de IA com `iconKey`, `calorias` e `observacao`

**Decision**: Estender o contrato da estimativa para incluir `iconKey` obrigatório e `observacao` textual; `calorias` permanece obrigatória.

**Rationale**:
- Formaliza a regra de negócio da spec 003.
- Permite exibir ícone consistente na lista sem heurística local frágil.
- `observacao` cobre casos de quantidade ausente com premissas explícitas.

**Alternatives considered**:
- Inferir ícone somente no cliente a partir da descrição (rejeitado por divergência com requisito).
- Tornar `iconKey` opcional sem fallback (rejeitado por risco de UI inconsistente).

---

### DEC-004: Política de fallback de ícone

**Decision**: Aceitar somente ícones suportados (`breakfast`, `lunch`, `dinner`, `snack`, `drink`, `dessert`, `default`). Valor inválido ou ausente deve virar `default` antes de salvar.

**Rationale**:
- Impede renderização de ícone inválido.
- Garante previsibilidade no histórico de refeições.
- Facilita testes unitários de validação.

**Alternatives considered**:
- Quebrar fluxo em ícone inválido (rejeitado por pior UX).
- Criar ícone dinamicamente (rejeitado por fora do escopo).

---

### DEC-005: Responsividade sem novos fluxos

**Decision**: Definir comportamento por breakpoint somente para layout (padding, largura máxima de conteúdo e densidade), mantendo os mesmos passos de interação.

**Rationale**:
- Preserva simplicidade e poucos cliques.
- Atende requisito de telas pequenas e grandes.

**Alternatives considered**:
- Criar telas diferentes por tamanho (rejeitado por custo e risco de divergência funcional).

---

## Dependências e Impactos

- Nenhuma nova dependência obrigatória além das já presentes no app.
- Impacto principal em `themes/`, `features/home/`, `models/meal.dart` e contrato em `services/ai_adapter/`.

## Resultado

Todas as ambiguidades técnicas da spec 003 foram resolvidas sem violar a constitution.

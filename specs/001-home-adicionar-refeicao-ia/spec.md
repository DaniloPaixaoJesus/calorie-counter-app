# Feature Specification: Home e adicionar refeição com estimativa calórica por IA

**Feature Branch**: `001-home-adicionar-refeicao-ia`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "Criar a feature \"Home e adicionar refeição com estimativa calórica por IA\""

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar refeição por texto (Priority: P1)

O usuário abre a tela inicial, toca em "Adicionar refeição", digita a descrição da refeição, solicita estimativa por IA, revisa a sugestão e confirma o registro.

**Why this priority**: fluxo central para uso diário sem dependência de áudio.

**Independent Test**: Abrir app -> Home -> Adicionar refeição -> digitar texto -> solicitar estimativa -> confirmar -> verificar lista e total.

**Acceptance Scenarios**:
1. **Given** app aberto na Home com estado vazio, **When** usuário adiciona refeição por texto e confirma, **Then** refeição aparece na lista e total é atualizado.
2. **Given** sugestão da IA retornou calorias e descrição, **When** usuário editar calorias antes de confirmar, **Then** valor salvo reflete edição.

---

### User Story 2 - Registrar refeição por áudio (Priority: P1)

O usuário inicia o fluxo de adicionar refeição por áudio, grava uma descrição falada, o app converte para texto, solicita estimativa por IA, permite revisão/edição e confirma.

**Why this priority**: acessibilidade e conveniência móvel; parity com entrada por texto.

**Independent Test**: Iniciar gravação -> finalizar -> verificar conversão -> solicitar estimativa -> revisar -> confirmar -> verificar lista e total.

**Acceptance Scenarios**:
1. **Given** permissão de microfone concedida, **When** usuário grava e envia, **Then** app exibe transcrição e pedido de estimativa.
2. **Given** permissão negada, **When** usuário tenta gravar, **Then** app mostra instruções para habilitar permissão.

---

### User Story 3 - Revisar e editar sugestão da IA (Priority: P2)

Após receber a estimativa, o usuário pode editar descrição e calorias antes de salvar ou cancelar.

**Why this priority**: garante controle do usuário sobre dados salvos.

**Independent Test**: Receber sugestão -> editar descrição/calorias -> confirmar -> verificar alterações na lista.

---

### Edge Cases

- Entrada ambígua: IA retorna baixa confiança; app deve mostrar aviso e permitir edição manual.
- Áudio inaudível: transcrição falha; app mostra opção de regravar.
- Texto muito longo: truncar visualmente na lista, salvar íntegro no registro.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A Home MUST exibir o total de calorias consumidas no dia no topo.
- **FR-002**: A Home MUST exibir a lista de refeições registradas e estado vazio quando não houver refeições.
- **FR-003**: Deve haver navegação inferior com "Home" e "Adicionar refeição".
- **FR-004**: Ao selecionar "Adicionar refeição" o usuário pode escolher entrada por texto ou por áudio.
- **FR-005**: Para entrada por texto, o usuário deve poder digitar livremente em campo multilinha.
- **FR-006**: Para entrada por áudio, o app deve capturar áudio, solicitar permissão de microfone e converter para texto preferencialmente on-device (transcrição local). Uso de serviços externos NÃO será utilizado no MVP; qualquer alternativa externa DEVE ser justificada e documentada em `plan.md`.
- **FR-007**: Após entrada, o app DEVE solicitar estimativa calórica por IA (pode usar adaptador mock no MVP).
- **FR-008**: A IA deve retornar descrição interpretada, calorias estimadas, observação curta e nível de confiança quando disponível.
- **FR-009**: Antes de salvar, o usuário deve revisar, editar (descrição e calorias) ou cancelar.
- **FR-010**: Ao confirmar, a refeição deve ser adicionada à lista e o total diário recalculado.
- **FR-011**: Se a IA retornar nível de confiança baixo (quando disponível), o app DEVE exibir um aviso claro e destacar os campos editáveis; o usuário PODE ainda salvar a refeição após revisão. O comportamento detalhado (threshold numérico, textos de aviso) DEVE ser definido no `plan.md`.

## Key Entities

- **Refeição**: `id`, `descricao` (string), `calorias` (inteiro), `timestamp`, `origem` (`texto`|`audio`), `ai_confidence` (decimal opcional), `nota` (string opcional)

## Success Criteria *(mandatory)*

- **SC-001**: Usuário consegue abrir a Home e ver o total diário no topo.
- **SC-002**: Usuário vê estado vazio quando não há refeições.
- **SC-003**: Usuário consegue adicionar refeição por texto e confirmar; registro aparece na lista.
- **SC-004**: Usuário consegue iniciar fluxo de áudio e ver transcrição (mock ok).
- **SC-005**: Usuário recebe estimativa calórica (mock) e pode revisar antes de salvar.
- **SC-006**: Usuário pode editar calorias antes de salvar e confirmação atualiza total.

## Assumptions

- Persistência inicial será em memória (processo vivo). Migração futura para persistência local/SQLite prevista.
- Não há autenticação nesta feature.
- Integração real com IA/LLM ficará desacoplada via adaptador; MVP pode usar mock.
- Permissões de microfone dependem do SO; fluxo deve guiar o usuário.
- Não implementar backend próprio nesta feature.

## Clarifications

### Session 2026-06-15

- Q: Transcrição de áudio no MVP — usar transcrição on‑device ou serviço externo? → A: Transcrição on‑device (Option A).
- Q: Comportamento quando confiança da IA é baixa? → A: Permitir salvar, exibir aviso e destacar edição recomendada (Option B).



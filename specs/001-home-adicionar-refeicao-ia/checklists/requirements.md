# Checklist: Unidade de Qualidade da Especificação — Home + Adicionar Refeição (IA)

**Purpose**: Testar a qualidade, completude e medida dos requisitos presentes em `spec.md`.
**Created**: 2026-06-15
**Feature**: [spec.md](spec.md)

### Requirement Completeness

- [ ] CHK001 - Estão todos os requisitos funcionais essenciais documentados (FR-001 a FR-010)? [Completeness, Spec §FR-001..FR-010]
- [ ] CHK002 - Existem requisitos explícitos para estado vazio, lista de refeições e total diário? [Completeness, Spec §FR-001, FR-002]
- [ ] CHK003 - A necessidade de pedir estimativa à IA e o uso de adaptador mock estão documentados? [Completeness, Spec §FR-007, Assumptions]

### Requirement Clarity

- [ ] CHK004 - As definições de entrada por texto e por áudio são claras e sem ambiguidade? [Clarity, Spec §FR-004, FR-005, FR-006]
- [ ] CHK005 - A resposta da IA (descrição, calorias, observação, confiança) está especificada com campos esperados? [Clarity, Spec §FR-008]

### Requirement Consistency

- [ ] CHK006 - Os fluxos de revisão/edição/cancelamento estão consistentes entre entrada por texto e por áudio? [Consistency, Spec §User Stories]
- [ ] CHK007 - A restrição "sem backend" é consistente com a exigência de transcrição e estimativa (uso de adaptador mock)? [Consistency, Spec §Assumptions, FR-006]

### Acceptance Criteria Quality

- [ ] CHK008 - Os critérios de aceite são mensuráveis e verificáveis (ex.: ver refeição na lista, total atualizado)? [Acceptance Criteria, Spec §SC-001..SC-006]

### Scenario Coverage

- [ ] CHK009 - Estão cobertos cenários primários, alternativos e de exceção: permissão negada, transcrição falha e baixa confiança da IA? [Coverage, Spec §Edge Cases]

### Edge Case Coverage

- [ ] CHK010 - Há requisitos para áudio inaudível, texto ambíguo e entrada muito longa? [Edge Case, Spec §Edge Cases]

### Non-Functional Requirements

- [ ] CHK011 - Há indicação sobre persistência (memória) e migração futura para local/SQLite? [NFR, Spec §Assumptions]
- [ ] CHK012 - Fluxo de áudio considera permissões do SO e comportamento quando permissão for negada? [NFR, Spec §User Story 2]

### Dependencies & Assumptions

- [ ] CHK013 - Todas as suposições relevantes (sem login, uso de mock para IA, persistência em memória) estão claramente listadas? [Dependencies, Spec §Assumptions]

### Ambiguities & Conflicts

- [ ] CHK014 - Existem termos vagos (ex.: "observação curta") que precisam ser quantificados ou exemplificados? [Ambiguity, Spec §FR-008]
- [ ] CHK015 - Há conflitos entre requisitos (por exemplo: demonstrar transcrição local vs. restrição de não usar backend)? [Conflict, Spec §FR-006, Assumptions]

--

If items above are unchecked, update `spec.md` before running `/speckit.plan`.

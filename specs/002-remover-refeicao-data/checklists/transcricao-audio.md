# Checklist de Qualidade de Requisitos: Transcrição de Áudio (AD-005)

**Purpose**: Validar completude, clareza, consistência e mensurabilidade dos requisitos de transcrição de áudio para gate de release
**Created**: 2026-06-16
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [ ] CHK001 Os requisitos de transcrição de áudio estão explicitamente vinculados ao escopo da feature 002 e ao adendo arquitetural registrado? [Completeness, Plan §AD-005]
- [ ] CHK002 Está definido de forma inequívoca que o limite máximo de gravação é de 30 segundos em todos os fluxos relevantes? [Clarity, Plan §AD-005]
- [ ] CHK003 Está definido que a parada manual pelo usuário é obrigatória, incluindo o comportamento quando o tempo chega a 0s? [Completeness, Plan §AD-005]
- [ ] CHK004 Está especificado que a transcrição textual só pode aparecer após o término da gravação, sem exceções não documentadas? [Clarity, Plan §AD-005]
- [ ] CHK005 Os requisitos descrevem o que deve ocorrer quando o usuário encerra antes dos 30s e quando o limite é atingido automaticamente? [Coverage, Gap]

## Requirement Clarity

- [ ] CHK006 O termo "término da gravação" está definido com precisão (parada manual, timeout de 30s, ou ambos)? [Ambiguity, Plan §AD-005]
- [ ] CHK007 O requisito de timer regressivo define formato esperado de apresentação (ex.: ss, mm:ss) e ponto de atualização visual? [Clarity, Gap]
- [ ] CHK008 O requisito diferencia claramente estados de UI durante gravação vs pós-gravação para evitar interpretações conflitantes? [Consistency, Plan §AD-005]
- [ ] CHK009 Há definição objetiva do que é "texto parcial" para impedir exibição antecipada indevida? [Clarity, Ambiguity]
- [ ] CHK010 Os limites de responsabilidade entre UI e mecanismo de transcrição estão descritos sem termos vagos? [Clarity, Plan §AD-005]

## Requirement Consistency

- [ ] CHK011 Os requisitos de áudio são consistentes com o princípio de simplicidade do MVP e não introduzem fluxos paralelos desnecessários? [Consistency, Spec §FR-013]
- [ ] CHK012 Os requisitos de áudio mantêm alinhamento com Offline First sem dependência implícita de internet não declarada? [Consistency, Constitution §III]
- [ ] CHK013 O adendo AD-005 não conflita com os cenários principais já definidos para navegação por data e remoção? [Consistency, Spec §User Stories]
- [ ] CHK014 A exigência de parada manual está consistente com a existência de limite automático em 30s, sem contradição normativa? [Conflict, Plan §AD-005]

## Acceptance Criteria Quality

- [ ] CHK015 Existem critérios de aceite mensuráveis para contagem regressiva (início em 30s, decremento contínuo, encerramento em 0s)? [Acceptance Criteria, Gap]
- [ ] CHK016 Existe critério de aceite mensurável para "texto apenas após término" incluindo ausência explícita durante captura? [Measurability, Plan §AD-005]
- [ ] CHK017 Os critérios de aceite distinguem claramente sucesso completo de transcrição vs término sem texto reconhecível? [Acceptance Criteria, Gap]
- [ ] CHK018 Há critérios objetivos para validar comportamento quando usuário interrompe imediatamente após iniciar gravação? [Coverage, Edge Case, Gap]

## Scenario Coverage

- [ ] CHK019 Os requisitos cobrem cenário primário de gravação completa com parada manual e exibição final de texto? [Coverage, Plan §AD-005]
- [ ] CHK020 Os requisitos cobrem cenário alternativo de término por atingir 30s sem ação do usuário? [Coverage, Plan §AD-005]
- [ ] CHK021 Os requisitos cobrem cenários de exceção (sem permissão de microfone, sem áudio reconhecível, timeout interno)? [Exception Flow, Gap]
- [ ] CHK022 Os requisitos cobrem cenários de recuperação após falha de transcrição (nova tentativa, retorno de estado da tela)? [Recovery Flow, Gap]

## Non-Functional Requirements

- [ ] CHK023 Existem requisitos de responsividade para atualização do timer regressivo sem degradar a experiência do usuário? [Non-Functional, Gap]
- [ ] CHK024 Existem requisitos de acessibilidade para leitura/entendimento do timer e estados de gravação? [Non-Functional, Accessibility, Gap]
- [ ] CHK025 Existem requisitos de privacidade para tratar áudio capturado e texto transcrito no contexto offline? [Non-Functional, Privacy, Gap]

## Dependencies & Assumptions

- [ ] CHK026 As premissas sobre disponibilidade do mecanismo de transcrição offline estão documentadas como suposições rastreáveis? [Assumption, Gap]
- [ ] CHK027 Dependências de plataforma (permissões de microfone, comportamento Android/iOS) estão especificadas no nível de requisito e não só em tarefa? [Dependency, Gap]
- [ ] CHK028 Está claro o que é obrigatório no MVP vs o que fica explicitamente fora de escopo para API de IA futura? [Scope Boundary, Plan §AD-005]

## Ambiguities & Conflicts

- [ ] CHK029 Há definição sem ambiguidade sobre prioridade entre "parada manual" e "encerramento automático ao chegar em 0s"? [Ambiguity, Conflict, Plan §AD-005]
- [ ] CHK030 Os requisitos evitam conflito entre "menor número de interações" e a exigência de clique manual para parar? [Conflict, Constitution §V]
- [ ] CHK031 Está documentado se o texto final deve substituir integralmente qualquer rascunho anterior de entrada do usuário ou se deve mesclar? [Ambiguity, Gap]
- [ ] CHK032 Os requisitos incluem decisão explícita sobre estratégia de internacionalização do texto transcrito (idioma esperado) para evitar comportamento implícito? [Gap, Non-Functional]

## Notes

- Checklist orientado para autor da especificação como gate de release.
- Itens marcados com [Gap], [Ambiguity], [Conflict], [Assumption] e [Dependency] indicam pontos a esclarecer antes de fechamento da spec.

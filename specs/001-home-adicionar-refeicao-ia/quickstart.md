# Quickstart — Validação manual da feature

**Objetivo**: Validar manualmente os fluxos centrais da feature no ambiente de desenvolvimento.

Pré-requisitos

- Ter Flutter SDK instalado e configurado.
- Rodar o app em um emulador ou dispositivo físico (Android/iOS).
- Permissões de microfone habilitadas para testes de áudio.

Passos para teste manual

1. Abrir o app e verificar a tela inicial:
   - Verificar que o topo mostra o total diário (0 quando vazio).
   - Verificar estado vazio (mensagem ou placeholder) quando não há refeições.
2. Navegar até "Adicionar refeição" pela barra inferior.
3. Entrada por texto:
   - Digitar: "comi arroz, feijão, frango grelhado e salada".
   - Solicitar estimativa IA (usando `ai_adapter_mock`).
   - Verificar que a sugestão exibe descrição, calorias, nota e confiança.
   - Editar calorias para um valor diferente e confirmar.
   - Verificar que a refeição aparece na Home e o total é atualizado.
4. Entrada por áudio:
   - Iniciar gravação, falar descrição da refeição e encerrar gravação.
   - Verificar transcrição exibida.
   - Solicitar estimativa IA (mock) e revisar antes de salvar.
5. Casos de erro:
   - Rejeitar permissão de microfone e verificar fluxo de erro com instruções.
   - Forçar baixa confiança (simular no mock) e verificar aviso de revisão.

Observações

- Para MVP, `ai_adapter_mock` devolve respostas determinísticas que facilitam testes automatizados.
- Documentar qualquer discrepância observada em `research.md`.


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
   - Iniciar gravação (botão microfone), falar descrição da refeição e encerrar gravação.
   - Verificar que a transcrição (via `AudioTranscriptionAdapter` offline) exibida no campo de descrição.
   - Solicitar estimativa IA (mock) e revisar antes de salvar.
   - Verificar transcrição com diferentes graus de confiança (alta → aceitar automaticamente; baixa → avisar para revisar).
5. Casos de erro:
   - Rejeitar permissão de microfone e verificar mensagem de erro com instrução para habilitar.
   - Forçar timeout de transcrição (simular no adaptador) e verificar mensagem apropriada.
   - Forçar baixa confiança (simular no mock) e verificar aviso de revisão.

Observações

- Para MVP, `ai_adapter_mock` devolve respostas determinísticas que facilitam testes automatizados.
- `OfflineAudioTranscriptionAdapter` (implementação padrão) usa `speech_to_text` e funciona offline sem qualquer API externa.
- Para validar a abstração: a interface `AudioTranscriptionAdapter` permite trocar a implementação (offline → API futura) sem qualquer mudança na UI ou lógica de negócio.
- Documentar qualquer discrepância observada em `research.md`.


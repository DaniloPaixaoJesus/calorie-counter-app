# Quickstart de Validação: Sincronização Online e Offline

## Pré-requisitos

- Flutter e Dart compatíveis com `app/pubspec.yaml`.
- Java 21.
- Banco de desenvolvimento configurado para o BFF.
- Credenciais Google de teste e duas contas: uma premium ativa e uma sem premium.
- Credenciais Google de teste e, quando usada operacionalmente, API key
  fornecida por ambiente, sem valor padrão no código.

## Preparação

```bash
cd app
flutter pub get
flutter test

cd ../bff
./mvnw test
```

Inicie o BFF com perfil de desenvolvimento e execute o app apontando `NUTRITY_BFF_BASE_URL` para esse ambiente.

## Cenário 1 — Bootstrap bidirecional

1. Sem login, crie duas refeições e altere a meta calórica.
2. Prepare na conta premium uma refeição de ID distinto e outra com o mesmo ID de uma refeição local, mas conteúdo diferente.
3. Faça login.
4. Continue usando o app enquanto o estado estiver “Sincronizando”.
5. Confirme:
   - nenhum bloqueio do CRUD local;
   - IDs exclusivos presentes nos dois lados;
   - versão remota mantida no conflito inicial;
   - nenhuma duplicação após três retries;
   - meta calórica convergente.

## Cenário 2 — Recuperação de compra

1. Após o carregamento inicial, confirme que “Recuperar compra” aparece
   diretamente na seleção de planos e toque nessa ação.
2. Entre com uma conta Google que possua premium ativo no BFF.
3. Confirme que a sessão é restaurada, a Home é aberta e os dados remotos são
   recuperados pelo bootstrap.
4. Repita com um e-mail inexistente e com uma conta sem premium ativo.
5. Confirme que nenhuma conta ou assinatura é criada, o Google é desconectado,
   a seleção de planos volta a ser exibida e o aviso identifica o e-mail
   consultado como sem conta Premium ativa.
6. Em uma tela com 320 px de largura, confirme que cabeçalho, cards, selos,
   benefícios e ações permanecem legíveis e acessíveis por rolagem.

## Cenário 3 — Offline, retry e conflito

1. Com premium ativo, coloque o dispositivo A offline.
2. Edite uma refeição em A e outra versão da mesma refeição no dispositivo B.
3. Garanta que a edição de A tenha `modifiedAt` posterior.
4. Reconecte A sem criar nova alteração nem tocar em “Tentar agora”.
5. Aguarde a sincronização automática.
6. Confirme que a edição de A vence, os dois dispositivos convergem e a outbox é reconhecida uma única vez.

Repita com remoção versus edição para validar tombstone e LWW.

## Cenário 4 — Expiração e renovação

1. Com sessão autenticada, altere o premium para inativo no BFF.
2. Crie e edite dados no app.
3. Confirme que:
   - o uso local continua;
   - as operações permanecem pendentes;
   - não há envio enquanto inativo;
   - a IA aplica limites free.
4. Renove o premium e confirme envio automático sem duplicações.

## Cenário 5 — Logout

1. Crie uma pendência e deixe o BFF indisponível.
2. Solicite logout.
3. Confirme o aviso com quantidade de pendências e escolha “Sair e apagar”.
4. Interrompa o app durante a limpeza e reabra.
5. Confirme que a limpeza termina antes da UI e que não restam refeições, metas, outbox, cursor, token ou sessão.

## Cenário 6 — Isolamento entre contas

1. Sincronize a conta A e faça logout.
2. Entre com a conta B usando IDs de entidade iguais aos usados por A.
3. Confirme que B não lê, altera nem remove dados de A.

## Cenário 7 — Volume e interrupções

1. Prepare 1.000 registros locais e 1.000 remotos.
2. Interrompa rede/processo entre lotes e retome.
3. Valide convergência integral e ausência de duplicações.
4. Com 100 pendências, confirme conclusão em até 30 segundos em condições normais.

## Portões finais

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd ../bff
./mvnw test
```

Além dos comandos, validar o OpenAPI em [contracts/openapi.yaml](contracts/openapi.yaml), os estados de UI em [contracts/sync-ui.md](contracts/sync-ui.md) e os cenários manuais acima.

## Evidências da implementação — 27/07/2026

| Verificação automatizada | Resultado |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | Aprovado |
| `flutter analyze` | Aprovado, sem problemas |
| `flutter test` | Aprovado, 76 testes |
| `./mvnw -q test` | Aprovado, 20 testes |
| Migração Flyway em H2 de teste | Aprovada durante `SyncPersistenceTest` |
| Compatibilidade OpenAPI no app e BFF | Aprovada pelas suítes de contrato |

A suíte automatizada comprova domínio de conflitos, remote-wins inicial,
tombstones, lotes de até 100 operações, outbox, política free da IA com
premium inativo, contrato HTTP, persistência JPA e fluxos unitários de logout.
Também comprova gravação local antes do disparo remoto, retry automático após
indisponibilidade, espera de sincronização concorrente no logout e não
recriação da sessão no banco após a limpeza. O teste de regressão do bootstrap
comprova ainda que refeições preexistentes em `nutrity_meals` entram no feed
de sincronização e que a Home é atualizada após aplicá-las localmente. Os
testes de data cobrem a virada do dia com o app aberto e a conversão de
`mealAt` remoto para o fuso local antes de agrupar refeições.
Os testes de recuperação de compra comprovam que somente uma conta Premium
ativa restaura a sessão e inicia o bootstrap; e-mail sem plano não cria conta,
mantém o estado local sem premium e retorna à seleção de planos com aviso.
Também comprovam que a seleção de planos aberta automaticamente após o Splash
expõe a recuperação sem exigir a abertura prévia dos detalhes do Premium.
O teste compacto valida ainda a hierarquia visual da seleção e a ausência de
overflow em 320 × 640 px.

Os cenários manuais 1–7 e os critérios CS-001–CS-007 permanecem pendentes de
execução em dispositivo com BFF ativo, controle de conectividade e contas
Google de teste. Os testes de integração SQLite e widgets ainda abertos em
`tasks.md` também não foram substituídos por esta evidência automatizada.

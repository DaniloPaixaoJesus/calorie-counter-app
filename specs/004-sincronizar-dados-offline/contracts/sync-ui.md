# Contrato de Experiência: Estados de Sincronização

## Estados observáveis

| Estado | Mensagem/indicação | Ações |
|---|---|---|
| Local | Dados salvos neste dispositivo | Nenhuma exigida |
| Pendente | Alterações aguardando sincronização | Tentar agora |
| Sincronizando | Sincronizando dados | Uso do app permanece liberado |
| Atualizado | Dados sincronizados | Nenhuma |
| Pausado sem premium | Sincronização pausada; dados preservados | Renovar premium |
| Autenticação necessária | Entre novamente para sincronizar | Fazer login |
| Falha recuperável | Não foi possível sincronizar; dados estão seguros | Tentar novamente |

O estado deve possuir rótulo semântico e texto; cor ou ícone isolado não são suficientes.

## Login e bootstrap

1. Após autenticação Google e confirmação de premium, a pessoa entra no app imediatamente.
2. Dados locais permanecem visíveis enquanto o bootstrap roda.
3. Novas alterações entram na outbox normal.
4. O progresso pode ser retomado após fechamento ou falha.
5. Conflitos de identidade no bootstrap adotam a versão remota sem diálogo bloqueante.

## Recuperação de compra

1. A tela de planos oferece a ação “Recuperar compra” na área Premium.
2. A ação abre a autenticação Google e consulta o BFF sem criar conta ou
   conceder premium.
3. Se o e-mail pertencer a uma conta com premium ativo, o app restaura a
   sessão, abre a Home e inicia o bootstrap em segundo plano.
4. Se a conta não existir ou não possuir premium ativo, o app desconecta a
   identidade Google selecionada, retorna à seleção de planos e informa que
   nenhum plano ativo foi encontrado.
5. Cancelamento ou falha técnica mantém a pessoa no paywall e apresenta erro
   recuperável.

## Premium inativo

- O uso local e a IA em modalidade free continuam disponíveis.
- A outbox permanece intacta e recebe novas alterações.
- Envios remotos ficam pausados.
- Após renovação confirmada pelo BFF, o app retoma a fila automaticamente.

## Logout

1. Se não houver pendências, o logout limpa os dados locais e encerra a sessão.
2. Se houver pendências e o BFF estiver acessível, o app tenta sincronizar antes da confirmação final.
3. Se ainda restarem pendências, exibir:
   - quantidade de alterações que serão perdidas;
   - ação primária “Continuar no app”;
   - ação destrutiva “Sair e apagar”.
4. “Sair e apagar” inicia limpeza reiniciável; a tela seguinte só aparece após a limpeza local.
5. Ao reabrir durante uma limpeza interrompida, mostrar estado de inicialização sem conteúdo pessoal e finalizar a limpeza.

## Erros

- `401`: solicitar nova autenticação sem apagar dados.
- `403 PREMIUM_REQUIRED`: pausar a fila e aplicar modalidade free à IA.
- `409 IDEMPOTENCY_CONFLICT`: manter a operação e apresentar erro recuperável; não reenviar com payload alterado sob o mesmo ID.
- `413 BATCH_TOO_LARGE`: dividir o lote sem perder ordem.
- `429`: respeitar espera indicada e manter uso local.
- `5xx`, timeout ou offline: preservar a fila, tentar novamente
  automaticamente com backoff enquanto o app estiver ativo e oferecer retry
  manual.

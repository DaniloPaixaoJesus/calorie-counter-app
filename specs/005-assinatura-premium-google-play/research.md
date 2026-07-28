# Pesquisa: Assinatura Premium e Google Play Billing

## Validação de compra

**Decisão**: O BFF valida cada token de compra na Google Play Developer API antes de conceder acesso e usa o token como chave de unicidade global.

**Racional**: O cliente não é uma fonte confiável de pagamento. A validação remota confirma estado, produto, datas, renovação e reconhecimento; unicidade do token evita repetição e associação por outra conta.

**Alternativas consideradas**:
- Confiar na resposta do aplicativo: rejeitada por permitir adulteração.
- Conceder acesso antes da validação: rejeitada porque compras pendentes ou inválidas não podem ativar Premium.

**Referências**: [Segurança do Google Play Billing](https://developer.android.com/google/play/billing/security), [SubscriptionPurchaseV2](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get).

## Identidade antes do pagamento

**Decisão**: Exigir autenticação Google antes de iniciar a compra e incluir um identificador interno ofuscado da conta autenticada no fluxo de Billing. O BFF compara esse identificador retornado pela Google Play à identidade autenticada.

**Racional**: A Google Play não expõe ao BFF o e-mail da conta que realizou o pagamento. O identificador ofuscado protege a identidade e torna verificável o vínculo entre a compra e a conta Nutrity.

**Alternativas consideradas**:
- Autenticar depois de pagar: rejeitada porque não permite provar que a conta autenticada é a mesma vinculada ao pagamento.
- Enviar e-mail puro para a Google Play: rejeitada por privacidade.

**Referências**: [Identificadores de usuário do Billing](https://developer.android.com/google/play/billing/integrate#user-identifiers).

## Reconhecimento da compra

**Decisão**: Após validar e persistir uma compra nova, o BFF a reconhece na Google Play se ainda não estiver reconhecida; a operação é idempotente.

**Racional**: Uma assinatura não reconhecida dentro do prazo da Google Play pode ser reembolsada e revogada automaticamente. Fazer no BFF evita depender de o aparelho permanecer conectado.

**Alternativas consideradas**:
- Reconhecer apenas no app: rejeitada por falhar quando o app fecha ou perde rede.

**Referências**: [Processamento de compras](https://developer.android.com/google/play/billing/integrate#process).

## Eventos e reconciliação

**Decisão**: RTDN aciona consulta imediata do estado atual da assinatura; o BFF também reconcilia assinaturas ativas ao menos uma vez por hora e consulta compras anuladas em janela paginada.

**Racional**: RTDN pode ser entregue mais de uma vez e contém apenas um gatilho. A consulta à Google Play é autoritativa; a reconciliação cobre mensagens perdidas ou falhas internas.

**Alternativas consideradas**:
- Aplicar o payload RTDN diretamente: rejeitada porque eventos podem chegar fora de ordem.
- Consultar todas as assinaturas continuamente: rejeitada por risco de quota e custo.

**Referências**: [RTDN](https://developer.android.com/google/play/billing/rtdn-reference), [Compras anuladas](https://developers.google.com/android-publisher/voided-purchases).

## Estados de acesso

**Decisão**: Conceder acesso para ativa, teste e período de graça; manter acesso para cancelada até a expiração; bloquear para pendente, suspensa, pausada, expirada, reembolsada e revogada.

**Racional**: O estado retornado pela Google Play define a validade do direito. Datas precisam ser armazenadas em UTC e atualizadas a cada confirmação.

**Alternativas consideradas**:
- Usar somente a data local de expiração: rejeitada porque períodos de graça e recuperação alteram o estado efetivo.

**Referências**: [Ciclo de vida de assinaturas](https://developer.android.com/google/play/billing/lifecycle/subscriptions).

## Observabilidade e segurança

**Decisão**: Guardar credenciais da conta de serviço somente no BFF, mascarar tokens nos logs e registrar evento de auditoria por tentativa de validação/mudança de estado.

**Racional**: Tokens de compra e credenciais permitem acesso a dados financeiros; auditoria permite investigar fraude, falha de provider e redelivery de RTDN sem vazar segredo.

**Alternativas consideradas**:
- Logs com payload completo: rejeitada por exposição de credenciais e dados sensíveis.

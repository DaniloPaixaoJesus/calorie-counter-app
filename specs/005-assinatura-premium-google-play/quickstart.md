# Guia de Validação: Assinatura Premium

## Pré-requisitos

1. Produto, plano base e ofertas de assinatura configurados na Google Play Console.
2. Conta de teste adicionada ao canal de testes da Google Play.
3. Conta de serviço do BFF autorizada para consultar e reconhecer assinaturas.
4. Notificações RTDN configuradas para alcançar o ambiente de teste.
5. Aplicativo Android instalado a partir do canal de testes, não por instalação local.
6. BFF configurado com credenciais apenas por variáveis de ambiente ou gerenciador de segredos.

## Comandos de validação

```bash
cd app
flutter test
flutter analyze

cd ../bff
./mvnw test
```

Execute testes reais de pagamento somente no ambiente de testes da Google Play; a suíte automatizada deve usar doubles/fixtures.

## Cenários manuais

### 1. Contratação válida

1. Abra o aplicativo sem conta e acesse planos.
2. Selecione uma oferta e autentique com Google quando solicitado.
3. Confirme a compra na Google Play.
4. Confirme que o aplicativo mostra processamento e, depois da validação do BFF, mostra Premium ativo.
5. Confirme em `GET /subscriptions/me` que o plano é `PREMIUM`.

**Resultado esperado**: funcionalidades Premium são liberadas sem novo login; [subscription-api.md](contracts/subscription-api.md) retorna a assinatura sem token de compra.

### 2. Cancelamento e pendência

1. Cancele o diálogo de pagamento.
2. Tente uma compra pendente disponível no ambiente de testes.

**Resultado esperado**: cancelamento não altera acesso; pendência é apresentada sem liberar Premium.

### 3. Vínculo e idempotência

1. Envie a mesma confirmação de compra duas vezes.
2. Tente associar a compra a uma conta Google diferente.

**Resultado esperado**: a primeira operação é idempotente; a segunda é rejeitada com `PURCHASE_ALREADY_BOUND` ou `INVALID_PURCHASE`.

### 4. Restauração

1. Reinstale o aplicativo ou use outro aparelho com a mesma conta Google.
2. Autentique e acione restauração.

**Resultado esperado**: a assinatura ativa é recuperada sem duplicação.

### 5. Ciclo de vida

1. Dispare eventos de teste RTDN para renovação, cancelamento, período de graça, suspensão, recuperação, expiração e revogação.
2. Verifique o status retornado pelo BFF e o acesso às funcionalidades Premium.
3. Simule indisponibilidade transitória da Google Play e confirme que o acesso confirmado não é removido apenas pela falha.

**Resultado esperado**: o BFF consulta a Google Play antes da transição e a reconciliação horária corrige eventual divergência.

## Evidências

Anexe ao PR resultados de `flutter test`, `flutter analyze`, `./mvnw test`, cenário de contratação no canal de testes e evidências mascaradas de RTDN/reconciliação.

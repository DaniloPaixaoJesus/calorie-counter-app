# Contrato de Integração: Notificações da Google Play

## Objetivo

Receber notificações em tempo real como gatilho para atualizar assinaturas. A notificação não é uma prova de status: o BFF consulta a Google Play usando o token recebido antes de atualizar qualquer registro.

## Entrada

O provedor publica uma mensagem com token de compra, tipo de notificação e momento do evento. O adaptador de infraestrutura:

1. valida a origem e a estrutura da mensagem;
2. extrai o token sem registrá-lo integralmente;
3. inicia o caso de uso idempotente de sincronização;
4. consulta o estado atual da assinatura;
5. persiste a transição e o evento de auditoria;
6. responde sucesso somente após aceitar o processamento ou registrar a tentativa recuperável.

## Regras de processamento

- Entregas repetidas são esperadas e não podem duplicar assinatura, auditoria sem deduplicação ou acesso.
- Eventos atrasados ou fora de ordem não prevalecem sobre a consulta autoritativa atual.
- Renovação, recuperação, cancelamento, período de graça, suspensão, pausa, expiração, reembolso e revogação devem resultar em atualização do direito de acesso.
- Compra anulada remove o acesso assim que confirmada.
- Falha transitória de consulta deve gerar resultado recuperável e nova tentativa; não deve rebaixar acesso já confirmado sem evidência de expiração ou revogação.

## Reconciliação

Um processo agendado:

- executa ao menos uma vez por hora;
- verifica registros ativos e compras anuladas desde o último cursor confirmado;
- pagina resultados até concluir a janela;
- atualiza o cursor somente após processamento bem-sucedido;
- registra métricas de atraso, falha, quantidade processada e divergências corrigidas.

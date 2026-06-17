# BFF

Backend for Frontend do Calorie Counter App, implementado com Java 21 e Spring Boot.

## Requisitos

- Java 21
- Maven 3.x

## Configuração local

Crie um arquivo `.env` no diretório `bff/` com as variáveis usadas pela aplicação:

```env
PORT=8080
BFF_PROFILES_ACTIVE=local
LOG_LEVEL_ROOT=INFO
JPA_SHOW_SQL=true

APP_API_SECURITY_ENABLED=true
APP_API_KEY=
APP_API_KEY_HEADER=X-App-Api-Key
APP_API_RATE_LIMIT_PER_MINUTE=30

AI_DEFAULT_PROVIDER=mock
OPENAI_API_KEY=
OPENAI_BASE_URL=https://api.openai.com
OPENAI_MODEL=gpt-4.1-mini
OPENAI_TIMEOUT_SECONDS=20

CNARH_40_BASE_URL=http://localhost:9001
```

O `.env` não deve ser versionado. Preencha `APP_API_KEY` com um segredo compartilhado entre o app e o BFF. Para usar o provider real da OpenAI, preencha `OPENAI_API_KEY` localmente e altere `AI_DEFAULT_PROVIDER=openai-gpt`, ou envie `"provider": "openai-gpt"` na requisição.

## Executar

Na pasta `bff/`:

```bash
set -a
source .env
set +a
mvn spring-boot:run
```

A API sobe por padrão em:

```text
http://localhost:8080/bff-service
```

## Endpoint de IA

### Estimar calorias de uma refeição

```http
POST /bff-service/ai/meal-estimates
Content-Type: application/json
```

Request:

```json
{
  "descricao": "arroz, feijão e frango grelhado",
  "provider": "mock"
}
```

Response:

```json
{
  "descricaoInterpretada": "arroz, feijão e frango grelhado",
  "calorias": 530,
  "observacao": "Estimativa baseada na soma de porções médias reconhecidas.",
  "confidence": 0.92,
  "iconKey": "grain",
  "provider": "mock"
}
```

### Teste com curl

Provider mock:

```bash
curl -X POST http://localhost:8080/bff-service/ai/meal-estimates \
  -H "Content-Type: application/json" \
  -H "X-App-Api-Key: $APP_API_KEY" \
  -d '{
    "descricao": "arroz, feijão e frango grelhado",
    "provider": "mock"
  }'
```

Provider OpenAI GPT:

```bash
curl -X POST http://localhost:8080/bff-service/ai/meal-estimates \
  -H "Content-Type: application/json" \
  -H "X-App-Api-Key: $APP_API_KEY" \
  -d '{
    "descricao": "banana, ovo mexido e pão francês",
    "provider": "openai-gpt"
  }'
```

## Providers de IA

- `mock`: provider padrão, sem dependência externa, útil para desenvolvimento e testes.
- `openai-gpt`: usa a OpenAI Responses API em `/v1/responses`.

Para adicionar novos providers, implemente `AiProviderAdapter` e registre a classe como bean Spring.

## Segurança do endpoint de IA

As rotas `/ai/**` exigem o header configurado em `APP_API_KEY_HEADER`:

```http
X-App-Api-Key: <APP_API_KEY>
```

Também há rate limit em memória por API key + IP do cliente. O limite padrão é `APP_API_RATE_LIMIT_PER_MINUTE=30`.

## Testes

Na pasta `bff/`:

```bash
mvn test
```

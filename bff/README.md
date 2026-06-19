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
  "descricao": "arroz, feijão e frango grelhado"
}
```

O campo `provider` é opcional. Quando ausente, o BFF usa `AI_DEFAULT_PROVIDER`.

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
    "descricao": "arroz, feijão e frango grelhado"
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

Exemplo equivalente ao app publicado:

```bash
curl --location 'https://nutrity-bff-695228964694.southamerica-east1.run.app/bff-service/ai/meal-estimates' \
  --header "X-App-Api-Key: $APP_API_KEY" \
  --header 'Content-Type: application/json' \
  --data '{
    "descricao": "pao frances com ovo frito e xicara de cafe com leite"
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

O app mobile também aplica um limite local de 60 estimativas por dia para ajudar no controle de uso durante o MVP.

## Testes

Na pasta `bff/`:

```bash
mvn test
```

## Docker

Build local:

```bash
docker build -t calorie-counter-bff .
```

Execução local:

```bash
docker run --rm -p 8080:8080 \
  -e APP_API_KEY="$APP_API_KEY" \
  -e AI_DEFAULT_PROVIDER=mock \
  calorie-counter-bff
```

Com Docker Compose:

```bash
cd bff
docker compose up --build
```

Se estiver usando o binário legado:

```bash
cd bff
docker-compose up --build
```

A aplicação ficará disponível em:

```text
http://localhost:8080/bff-service
```

## Deploy no Google Cloud Run

O deploy usa:

- Cloud Build para criar a imagem a partir do `Dockerfile`
- Artifact Registry para armazenar a imagem Docker
- Cloud Run para publicar o serviço
- Secret Manager para `APP_API_KEY` e `OPENAI_API_KEY`

Pré-requisitos:

```bash
gcloud init
gcloud config set project <PROJECT_ID>
```

Crie os secrets uma vez:

```bash
printf '%s' '<sua-app-api-key>' | \
  gcloud secrets create app-api-key --data-file=- --project <PROJECT_ID>

printf '%s' '<sua-openai-api-key>' | \
  gcloud secrets create openai-api-key --data-file=- --project <PROJECT_ID>
```

Execute o deploy a partir da raiz do repositório:

```bash
PROJECT_ID=<PROJECT_ID> \
REGION=southamerica-east1 \
SERVICE_NAME=bff-service \
AR_REPOSITORY=calorie-counter \
AI_DEFAULT_PROVIDER=openai-gpt \
bff/scripts/deploy-cloud-run.sh
```

Variáveis úteis:

```bash
ALLOW_UNAUTHENTICATED=true
MEMORY=512Mi
CPU=1
TIMEOUT=60s
MAX_INSTANCES=3
APP_API_KEY_SECRET_NAME=app-api-key
OPENAI_API_KEY_SECRET_NAME=openai-api-key
```

O Cloud Run injeta a variável `PORT`; o BFF usa `server.port=${PORT:8080}` e já está pronto para esse contrato.

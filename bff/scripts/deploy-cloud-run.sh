#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BFF_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}"
REGION="${REGION:-southamerica-east1}"
SERVICE_NAME="${SERVICE_NAME:-bff-service}"
AR_REPOSITORY="${AR_REPOSITORY:-calorie-counter}"
IMAGE_NAME="${IMAGE_NAME:-bff-service}"
IMAGE_TAG="${IMAGE_TAG:-$(git -C "${BFF_DIR}" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
ALLOW_UNAUTHENTICATED="${ALLOW_UNAUTHENTICATED:-true}"

BFF_PROFILES_ACTIVE="${BFF_PROFILES_ACTIVE:-cloud}"
LOG_LEVEL_ROOT="${LOG_LEVEL_ROOT:-INFO}"
JPA_SHOW_SQL="${JPA_SHOW_SQL:-false}"

APP_API_SECURITY_ENABLED="${APP_API_SECURITY_ENABLED:-true}"
APP_API_KEY_HEADER="${APP_API_KEY_HEADER:-X-App-Api-Key}"
APP_API_RATE_LIMIT_PER_MINUTE="${APP_API_RATE_LIMIT_PER_MINUTE:-30}"

AI_DEFAULT_PROVIDER="${AI_DEFAULT_PROVIDER:-openai-gpt}"
OPENAI_BASE_URL="${OPENAI_BASE_URL:-https://api.openai.com}"
OPENAI_MODEL="${OPENAI_MODEL:-gpt-4.1-mini}"
OPENAI_TIMEOUT_SECONDS="${OPENAI_TIMEOUT_SECONDS:-20}"

APP_API_KEY_SECRET_NAME="${APP_API_KEY_SECRET_NAME:-app-api-key}"
OPENAI_API_KEY_SECRET_NAME="${OPENAI_API_KEY_SECRET_NAME:-openai-api-key}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "PROJECT_ID não definido. Configure com: export PROJECT_ID=<seu-projeto-gcp>" >&2
  exit 1
fi

IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Comando obrigatório não encontrado: $1" >&2
    exit 1
  fi
}

secret_exists() {
  local secret_name="$1"
  gcloud secrets describe "${secret_name}" --project "${PROJECT_ID}" >/dev/null 2>&1
}

require_command gcloud

echo "Projeto: ${PROJECT_ID}"
echo "Região: ${REGION}"
echo "Serviço: ${SERVICE_NAME}"
echo "Imagem: ${IMAGE_URI}"

echo "Habilitando APIs necessárias..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  --project "${PROJECT_ID}"

echo "Garantindo repositório Docker no Artifact Registry..."
if ! gcloud artifacts repositories describe "${AR_REPOSITORY}" \
  --project "${PROJECT_ID}" \
  --location "${REGION}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPOSITORY}" \
    --project "${PROJECT_ID}" \
    --repository-format docker \
    --location "${REGION}" \
    --description "Docker images do Calorie Counter"
fi

echo "Validando secrets..."
SECRET_ARGS=()
if [[ -n "${APP_API_KEY_SECRET_NAME}" ]]; then
  if ! secret_exists "${APP_API_KEY_SECRET_NAME}"; then
    echo "Secret '${APP_API_KEY_SECRET_NAME}' não existe. Crie com:" >&2
    echo "printf '%s' '<sua-app-api-key>' | gcloud secrets create ${APP_API_KEY_SECRET_NAME} --data-file=- --project ${PROJECT_ID}" >&2
    exit 1
  fi
  SECRET_ARGS+=("APP_API_KEY=${APP_API_KEY_SECRET_NAME}:latest")
elif [[ -n "${APP_API_KEY:-}" ]]; then
  echo "APP_API_KEY será enviada como variável de ambiente. Prefira Secret Manager em produção." >&2
  ENV_APP_API_KEY="${APP_API_KEY}"
else
  echo "Defina APP_API_KEY_SECRET_NAME ou APP_API_KEY." >&2
  exit 1
fi

if [[ -n "${OPENAI_API_KEY_SECRET_NAME}" ]]; then
  if ! secret_exists "${OPENAI_API_KEY_SECRET_NAME}"; then
    echo "Secret '${OPENAI_API_KEY_SECRET_NAME}' não existe. Crie com:" >&2
    echo "printf '%s' '<sua-openai-api-key>' | gcloud secrets create ${OPENAI_API_KEY_SECRET_NAME} --data-file=- --project ${PROJECT_ID}" >&2
    exit 1
  fi
  SECRET_ARGS+=("OPENAI_API_KEY=${OPENAI_API_KEY_SECRET_NAME}:latest")
elif [[ "${AI_DEFAULT_PROVIDER}" == "openai-gpt" && -z "${OPENAI_API_KEY:-}" ]]; then
  echo "AI_DEFAULT_PROVIDER=openai-gpt exige OPENAI_API_KEY_SECRET_NAME ou OPENAI_API_KEY." >&2
  exit 1
elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY será enviada como variável de ambiente. Prefira Secret Manager em produção." >&2
  ENV_OPENAI_API_KEY="${OPENAI_API_KEY}"
fi

echo "Executando testes locais..."
(cd "${BFF_DIR}" && mvn test)

echo "Build e push da imagem com Cloud Build..."
gcloud builds submit "${BFF_DIR}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --tag "${IMAGE_URI}"

ENV_VARS=(
  "BFF_PROFILES_ACTIVE=${BFF_PROFILES_ACTIVE}"
  "LOG_LEVEL_ROOT=${LOG_LEVEL_ROOT}"
  "JPA_SHOW_SQL=${JPA_SHOW_SQL}"
  "APP_API_SECURITY_ENABLED=${APP_API_SECURITY_ENABLED}"
  "APP_API_KEY_HEADER=${APP_API_KEY_HEADER}"
  "APP_API_RATE_LIMIT_PER_MINUTE=${APP_API_RATE_LIMIT_PER_MINUTE}"
  "AI_DEFAULT_PROVIDER=${AI_DEFAULT_PROVIDER}"
  "OPENAI_BASE_URL=${OPENAI_BASE_URL}"
  "OPENAI_MODEL=${OPENAI_MODEL}"
  "OPENAI_TIMEOUT_SECONDS=${OPENAI_TIMEOUT_SECONDS}"
)

if [[ -n "${ENV_APP_API_KEY:-}" ]]; then
  ENV_VARS+=("APP_API_KEY=${ENV_APP_API_KEY}")
fi

if [[ -n "${ENV_OPENAI_API_KEY:-}" ]]; then
  ENV_VARS+=("OPENAI_API_KEY=${ENV_OPENAI_API_KEY}")
fi

DEPLOY_ARGS=(
  run deploy "${SERVICE_NAME}"
  --project "${PROJECT_ID}"
  --region "${REGION}"
  --image "${IMAGE_URI}"
  --platform managed
  --port 8080
  --memory "${MEMORY:-512Mi}"
  --cpu "${CPU:-1}"
  --timeout "${TIMEOUT:-60s}"
  --max-instances "${MAX_INSTANCES:-3}"
  --set-env-vars "$(IFS=,; echo "${ENV_VARS[*]}")"
)

if [[ "${#SECRET_ARGS[@]}" -gt 0 ]]; then
  DEPLOY_ARGS+=(--set-secrets "$(IFS=,; echo "${SECRET_ARGS[*]}")")
fi

if [[ "${ALLOW_UNAUTHENTICATED}" == "true" ]]; then
  DEPLOY_ARGS+=(--allow-unauthenticated)
else
  DEPLOY_ARGS+=(--no-allow-unauthenticated)
fi

echo "Deploy no Cloud Run..."
gcloud "${DEPLOY_ARGS[@]}"

echo "Deploy concluído."

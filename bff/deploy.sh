#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_ID="${PROJECT_ID:-nutrity-499722}"
REGION="${REGION:-southamerica-east1}"
REPOSITORY="${REPOSITORY:-nutrity}"
SERVICE_NAME="${SERVICE_NAME:-nutrity-bff}"
IMAGE_NAME="${IMAGE_NAME:-nutrity-bff}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

LOCAL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
REMOTE_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Erro: o comando '$1' não está instalado ou não está no PATH." >&2
    exit 1
  fi
}

require_command docker
require_command gcloud

echo "Iniciando deploy do ${SERVICE_NAME}"
echo "Imagem: ${REMOTE_IMAGE}"

echo "[1/4] Construindo a imagem Docker..."
docker build --tag "${LOCAL_IMAGE}" "${SCRIPT_DIR}"

echo "[2/4] Criando a tag do Artifact Registry..."
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"

echo "[3/4] Enviando a imagem..."
docker push "${REMOTE_IMAGE}"

echo "[4/4] Publicando no Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --project "${PROJECT_ID}" \
  --image "${REMOTE_IMAGE}" \
  --region "${REGION}"

echo "Deploy concluído com sucesso."

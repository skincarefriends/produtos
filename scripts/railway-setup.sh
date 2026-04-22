#!/usr/bin/env bash
# Provisionamento completo do projeto no Railway (IaC via CLI).
# Uso:
#   1. Instale a CLI: https://docs.railway.com/guides/cli
#   2. railway login
#   3. bash scripts/railway-setup.sh
#
# Pré-requisito: arquivo .env na raiz com as variáveis do projeto.

set -euo pipefail

PROJECT_NAME="${1:-skincarefriends}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v railway >/dev/null 2>&1; then
  echo "✗ railway CLI não encontrada. Instale em https://docs.railway.com/guides/cli"
  exit 1
fi

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "✗ .env não encontrado em $ROOT_DIR"
  exit 1
fi

echo "→ verificando login"
railway whoami >/dev/null 2>&1 || { echo "✗ rode: railway login"; exit 1; }

echo "→ criando projeto: $PROJECT_NAME"
railway init --name "$PROJECT_NAME" || echo "  (projeto já pode existir, seguindo)"

echo "→ adicionando MongoDB"
railway add --database mongo || echo "  (mongo já pode estar adicionado)"

echo "→ aplicando variáveis do .env no serviço web"
# Lê .env linha a linha, pula comentários e vazios. MONGODB_URI é sobrescrita
# para apontar pro plugin do Railway via referência de variável.
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  key="${key// /}"
  [[ -z "$key" ]] && continue
  if [[ "$key" == "MONGODB_URI" ]]; then
    value='${{ MongoDB.MONGO_URL }}'
  fi
  echo "  · $key"
  railway variables --set "$key=$value" >/dev/null
done < "$ROOT_DIR/.env"

echo "→ deploy"
railway up --detach

echo "→ gerando domínio público"
railway domain || true

echo "✓ pronto. use 'railway open' pra abrir o dashboard."

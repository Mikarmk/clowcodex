#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/.env"
fi

: "${SERVER_HOST:?SERVER_HOST is required}"
: "${REPO_URL:?REPO_URL is required}"
: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"

SERVER_USER="${SERVER_USER:-root}"
SERVER_PORT="${SERVER_PORT:-22}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REMOTE_REPO_DIR="${CLOWCODEX_REPO_DIR:-/opt/clowcodex/repo}"
REMOTE_ENV_FILE="${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}"

ssh -p "${SERVER_PORT}" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" "mkdir -p '${REMOTE_REPO_DIR}'"

git -C "${REPO_ROOT}" push origin "${REPO_BRANCH}"

ssh -p "${SERVER_PORT}" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" "if [ ! -d '${REMOTE_REPO_DIR}/.git' ]; then git clone --branch '${REPO_BRANCH}' '${REPO_URL}' '${REMOTE_REPO_DIR}'; else git -C '${REMOTE_REPO_DIR}' fetch origin && git -C '${REMOTE_REPO_DIR}' checkout '${REPO_BRANCH}' && git -C '${REMOTE_REPO_DIR}' pull --ff-only origin '${REPO_BRANCH}'; fi"

ssh -p "${SERVER_PORT}" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" "cat > '${REMOTE_ENV_FILE}' <<'EOF'
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
OPENAI_API_KEY=${OPENAI_API_KEY:-}
CLOWCODEX_SERVICE_USER=${CLOWCODEX_SERVICE_USER:-clowcodex}
CLOWCODEX_SERVICE_GROUP=${CLOWCODEX_SERVICE_GROUP:-clowcodex}
CLOWCODEX_BASE_DIR=${CLOWCODEX_BASE_DIR:-/opt/clowcodex}
CLOWCODEX_REPO_DIR=${CLOWCODEX_REPO_DIR:-/opt/clowcodex/repo}
CLOWCODEX_WORKDIR=${CLOWCODEX_WORKDIR:-/opt/clowcodex/repo}
CLOWCODEX_ENV_FILE=${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}
CLOWCODEX_GATEWAY_PORT=${CLOWCODEX_GATEWAY_PORT:-18789}
CLOWCODEX_TELEGRAM_DM_POLICY=${CLOWCODEX_TELEGRAM_DM_POLICY:-pairing}
CLOWCODEX_TELEGRAM_ALLOW_FROM_JSON=${CLOWCODEX_TELEGRAM_ALLOW_FROM_JSON:-[]}
CLOWCODEX_CODEX_MODEL=${CLOWCODEX_CODEX_MODEL:-gpt-5.3-codex}
CLOWCODEX_CODEX_REASONING=${CLOWCODEX_CODEX_REASONING:-high}
CLOWCODEX_COPY_ROOT_CODEX_AUTH=${CLOWCODEX_COPY_ROOT_CODEX_AUTH:-1}
REPO_BRANCH=${REPO_BRANCH}
EOF
chmod 600 '${REMOTE_ENV_FILE}'"

ssh -p "${SERVER_PORT}" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" "cd '${REMOTE_REPO_DIR}' && bash scripts/bootstrap-server.sh && REPO_ROOT='${REMOTE_REPO_DIR}' bash scripts/install-openclaw.sh && bash scripts/smoke-test.sh"


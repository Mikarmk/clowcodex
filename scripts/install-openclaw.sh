#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export REPO_ROOT

SERVICE_USER="${CLOWCODEX_SERVICE_USER:-clowcodex}"
SERVICE_GROUP="${CLOWCODEX_SERVICE_GROUP:-$SERVICE_USER}"
BASE_DIR="${CLOWCODEX_BASE_DIR:-/opt/clowcodex}"
REPO_DIR="${CLOWCODEX_REPO_DIR:-$BASE_DIR/repo}"
WORKDIR="${CLOWCODEX_WORKDIR:-$REPO_DIR}"
ENV_FILE="${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}"
SERVICE_NAME="clowcodex-openclaw.service"
SERVICE_HOME="/home/${SERVICE_USER}"
OPENCLAW_CONFIG_DIR="${SERVICE_HOME}/.openclaw"
CODEX_CONFIG_DIR="${SERVICE_HOME}/.codex"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"

export CLOWCODEX_SERVICE_USER="${SERVICE_USER}"
export CLOWCODEX_SERVICE_GROUP="${SERVICE_GROUP}"
export CLOWCODEX_BASE_DIR="${BASE_DIR}"
export CLOWCODEX_REPO_DIR="${REPO_DIR}"
export CLOWCODEX_WORKDIR="${WORKDIR}"
export CLOWCODEX_GATEWAY_PORT="${CLOWCODEX_GATEWAY_PORT:-18789}"
export CLOWCODEX_TELEGRAM_DM_POLICY="${CLOWCODEX_TELEGRAM_DM_POLICY:-pairing}"
export CLOWCODEX_TELEGRAM_ALLOW_FROM_JSON="${CLOWCODEX_TELEGRAM_ALLOW_FROM_JSON:-[]}"
export CLOWCODEX_CODEX_MODEL="${CLOWCODEX_CODEX_MODEL:-gpt-5.3-codex}"
export CLOWCODEX_CODEX_REASONING="${CLOWCODEX_CODEX_REASONING:-high}"
export TELEGRAM_BOT_TOKEN

install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "${BASE_DIR}" "${REPO_DIR}" "${OPENCLAW_CONFIG_DIR}" "${CODEX_CONFIG_DIR}"

npm install -g openclaw@latest
if ! command -v codex >/dev/null 2>&1; then
  npm install -g @openai/codex@latest
fi

python3 - <<'PY' > "${OPENCLAW_CONFIG_DIR}/openclaw.json"
import json
import os
from pathlib import Path
from string import Template

template = Path(os.environ["REPO_ROOT"] + "/config/openclaw.json.template").read_text()
expanded = Template(template).substitute(os.environ)
json.loads(expanded)
print(expanded)
PY

python3 - <<'PY' > "${CODEX_CONFIG_DIR}/config.toml"
import os
from pathlib import Path
from string import Template

template = Path(os.environ["REPO_ROOT"] + "/config/codex.config.toml.template").read_text()
print(Template(template).substitute(os.environ))
PY

if [[ "${CLOWCODEX_COPY_ROOT_CODEX_AUTH:-1}" == "1" && -f /root/.codex/auth.json ]]; then
  install -m 0600 -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" /root/.codex/auth.json "${CODEX_CONFIG_DIR}/auth.json"
fi

install -m 0644 "${REPO_ROOT}/deploy/systemd/clowcodex-openclaw.service" "/etc/systemd/system/${SERVICE_NAME}"
sed -i \
  -e "s|__SERVICE_USER__|${SERVICE_USER}|g" \
  -e "s|__SERVICE_GROUP__|${SERVICE_GROUP}|g" \
  -e "s|__REPO_DIR__|${REPO_DIR}|g" \
  -e "s|__HOME_DIR__|${SERVICE_HOME}|g" \
  -e "s|__ENV_FILE__|${ENV_FILE}|g" \
  "/etc/systemd/system/${SERVICE_NAME}"

chown "${SERVICE_USER}:${SERVICE_GROUP}" "${OPENCLAW_CONFIG_DIR}/openclaw.json" "${CODEX_CONFIG_DIR}/config.toml"
chmod 0600 "${OPENCLAW_CONFIG_DIR}/openclaw.json" "${CODEX_CONFIG_DIR}/config.toml"

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo "Install complete."
echo "openclaw: $(openclaw --version)"
echo "codex: $(codex --version)"

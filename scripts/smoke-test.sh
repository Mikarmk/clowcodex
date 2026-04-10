#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${CLOWCODEX_SERVICE_NAME:-clowcodex-openclaw.service}"
SERVICE_USER="${CLOWCODEX_SERVICE_USER:-clowcodex}"
GATEWAY_PORT="${CLOWCODEX_GATEWAY_PORT:-18789}"
ENV_FILE="${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

echo "== version checks =="
node --version
openclaw --version
codex --version

echo "== service checks =="
systemctl is-active --quiet "${SERVICE_NAME}"
systemctl --no-pager --full status "${SERVICE_NAME}" | sed -n '1,40p'

echo "== port checks =="
ss -ltn "( sport = :${GATEWAY_PORT} )" | sed -n '1,20p'

echo "== pairing visibility =="
sudo -u "${SERVICE_USER}" -H openclaw pairing list telegram || true

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "== telegram api =="
  curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq .
fi

echo "== recent logs =="
journalctl -u "${SERVICE_NAME}" -n 60 --no-pager


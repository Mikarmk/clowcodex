#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

SERVICE_USER="${CLOWCODEX_SERVICE_USER:-clowcodex}"
SERVICE_GROUP="${CLOWCODEX_SERVICE_GROUP:-$SERVICE_USER}"
BASE_DIR="${CLOWCODEX_BASE_DIR:-/opt/clowcodex}"
REPO_DIR="${CLOWCODEX_REPO_DIR:-$BASE_DIR/repo}"
ENV_FILE="${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg git jq rsync python3

NODE_MAJOR="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/' || true)"
if [[ -z "${NODE_MAJOR}" || "${NODE_MAJOR}" -lt 24 ]]; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install -y nodejs
fi

if ! getent group "${SERVICE_GROUP}" >/dev/null 2>&1; then
  groupadd --system "${SERVICE_GROUP}"
fi

if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
  useradd --system --gid "${SERVICE_GROUP}" --create-home --home-dir "/home/${SERVICE_USER}" --shell /bin/bash "${SERVICE_USER}"
fi

install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "${BASE_DIR}"
install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "${REPO_DIR}"
install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "/home/${SERVICE_USER}/.openclaw"
install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "/home/${SERVICE_USER}/.codex"
install -d -o root -g root -m 0750 "$(dirname "${ENV_FILE}")"

echo "Bootstrap complete."
echo "Node: $(node -v)"
echo "npm: $(npm -v)"


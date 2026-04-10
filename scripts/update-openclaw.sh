#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${CLOWCODEX_ENV_FILE:-/etc/clowcodex/clowcodex.env}"
REPO_BRANCH="${REPO_BRANCH:-main}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

cd "${REPO_ROOT}"
git fetch origin
git checkout "${REPO_BRANCH}"
git pull --ff-only origin "${REPO_BRANCH}"

REPO_ROOT="${REPO_ROOT}" "${SCRIPT_DIR}/install-openclaw.sh"


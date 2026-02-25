#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/solosoyfranco/domum-core.git"
INSTALL_DIR_DEFAULT="/opt/domum-core"
BIN_PATH="/usr/local/bin/domum"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
INSTALL_DIR="${INSTALL_DIR:-$INSTALL_DIR_DEFAULT}"

echo "[domum] Installing prerequisites (curl, git)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates git

echo "[domum] Cloning or updating repo in ${INSTALL_DIR}..."
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  git -C "${INSTALL_DIR}" fetch --all --prune
  git -C "${INSTALL_DIR}" reset --hard origin/main
else
  rm -rf "${INSTALL_DIR}"
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

echo "[domum] Installing domum CLI to ${BIN_PATH}..."
install -m 0755 "${INSTALL_DIR}/bin/domum" "${BIN_PATH}"

echo "[domum] Creating config and secrets directories..."
mkdir -p "${INSTALL_DIR}/secrets"
mkdir -p "${INSTALL_DIR}/data"
mkdir -p "${INSTALL_DIR}/logs"

if [[ ! -f "${INSTALL_DIR}/config/domum.conf" ]]; then
  echo "[domum] ERROR: config/domum.conf not found in repo."
  echo "       Ensure your repo contains config/domum.conf."
  exit 1
fi

echo "[domum] Done."
echo "Next:"
echo "  sudo domum init"
echo "  sudo domum apply"
echo "[domum] Running init + apply..."
/usr/local/bin/domum init
/usr/local/bin/domum apply

echo "[domum] Done. Re-run anytime with the same curl command."

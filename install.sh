#!/bin/bash
# install.sh — cast-ledger installer.
# Copies the launcher into ~/.local/bin and both scripts into ~/.local/lib/cast-ledger.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CL_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; exit 1; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-ledger v${CL_VERSION} installer${C_RESET}\n"
printf "═════════════════════════════════════════════\n"
printf "  Tamper-evident session receipts from your cast.db.\n\n"

_step "Checking prerequisites..."
command -v python3 >/dev/null || _fail "python3 not found"
command -v sqlite3 >/dev/null || _warn "sqlite3 not found — runtime queries need it"
_ok "python3 available"

_step "Installing scripts + launcher..."
BIN_TARGET="${CAST_BIN_DIR:-$HOME/.local/bin}"
LIB_TARGET="${CAST_LIB_DIR:-$HOME/.local/lib/cast-ledger}"
mkdir -p "$BIN_TARGET" "$LIB_TARGET"
cp "$REPO_DIR/scripts/cast-ledger.py" "$LIB_TARGET/cast-ledger.py"
cp "$REPO_DIR/scripts/cast-provenance-chain.py" "$LIB_TARGET/cast-provenance-chain.py"
cp "$REPO_DIR/VERSION" "$LIB_TARGET/VERSION"
cp "$REPO_DIR/bin/cast-ledger" "$BIN_TARGET/cast-ledger"
chmod 755 "$BIN_TARGET/cast-ledger"
_ok "scripts → $LIB_TARGET/"
_ok "cast-ledger → $BIN_TARGET/cast-ledger"

if [[ ":$PATH:" != *":$BIN_TARGET:"* ]]; then
  _warn "$BIN_TARGET is not on your PATH — add it to your shell rc to use \`cast-ledger\` directly."
fi

printf "\n${C_BOLD}═════════════════════════════════════════════${C_RESET}\n"
printf "${C_GREEN}cast-ledger v${CL_VERSION} installed.${C_RESET}\n\n"
printf "${C_BOLD}Try it:${C_RESET}\n"
printf "  cast-ledger --last 1        # receipt for the most recent session\n"
printf "  cast-ledger verify-chain    # verify the provenance chain\n\n"

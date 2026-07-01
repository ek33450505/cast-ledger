#!/bin/bash
# uninstall.sh — remove cast-ledger launcher + scripts from common install locations.
set -euo pipefail

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_RESET=''
fi
_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-ledger uninstaller${C_RESET}\n"
printf "═════════════════════════════════════════════\n\n"

_step "Removing launcher..."
for d in "$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
  if [ -f "$d/cast-ledger" ]; then
    rm -f "$d/cast-ledger" && _ok "removed $d/cast-ledger"
  fi
done

_step "Removing scripts lib..."
LIB_TARGET="${CAST_LIB_DIR:-$HOME/.local/lib/cast-ledger}"
if [ -d "$LIB_TARGET" ]; then
  rm -f "$LIB_TARGET/cast-ledger.py" "$LIB_TARGET/cast-provenance-chain.py" "$LIB_TARGET/VERSION"
  rmdir "$LIB_TARGET" 2>/dev/null || true
  _ok "removed $LIB_TARGET"
fi

printf "\n${C_GREEN}cast-ledger uninstalled.${C_RESET}\n\n"
exit 0

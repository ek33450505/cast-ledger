# Contributing to cast-ledger

Thanks for your interest! cast-ledger renders tamper-evident session receipts from `cast.db` and maintains an optional provenance hash-chain. Contributions that add receipt sections, harden the digest/verify path, or improve cross-platform support are welcome.

## Prerequisites

- **bash** + **python3** — both ship with macOS / standard Linux
- **sqlite3** — required at runtime
- **BATS** — `brew install bats-core` (macOS) or `apt-get install bats` (Ubuntu)
- **ruff** (optional) — `pip install ruff` or `brew install ruff`

Stdlib Python only — no third-party dependencies.

## Quick Start

```bash
git clone https://github.com/ek33450505/cast-ledger
cd cast-ledger
bash install.sh
cast-ledger --last 1
```

`install.sh` is idempotent — safe to re-run.

## Layout

- `bin/cast-ledger` — bash launcher. Routes `provenance`/`verify-chain`/`version`/`help`; everything else passes through to the receipt renderer.
- `scripts/cast-ledger.py` — receipt renderer (read-only, `mode=ro`).
- `scripts/cast-provenance-chain.py` — the hash-chain (`append`/`verify`/`backfill`/`status`). Loads `cast-ledger.py` via importlib, so BOTH scripts must live in the same directory.

## How to Modify

- **Digest stability is a contract.** `_compute_digest` and `_build_receipt_data` define what a receipt commits to. Changing either changes every future digest and breaks `--verify` against old receipts — treat as a breaking change and bump the version.
- **Receipts stay read-only.** The renderer must never write to `cast.db`. Only the provenance chain writes, and only to `provenance_chain`.
- **Integrity export stays safe.** Never add a raw agent-output / freetext column to the receipt — keep the `_INTEGRITY_FREETEXT_COLS` allow-list-out intact.

## PR Checklist

- [ ] `bash install.sh && bash uninstall.sh` round-trip clean
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash -n bin/cast-ledger install.sh uninstall.sh` — all syntax-check
- [ ] `ruff check scripts/` clean (if ruff installed)
- [ ] Receipt render + `--verify` round-trip PASSES; a tampered receipt reports TAMPERED
- [ ] `provenance append` → `verify` PASSES; a modified chain row is detected
- [ ] No writes to `cast.db` except the `provenance_chain` table
- [ ] No hardcoded `/Users/<name>/` paths — use `$HOME` / `~/`
- [ ] `CHANGELOG.md` updated for user-visible changes

## Code Style

- All scripts: `set -euo pipefail`
- Quote variable expansions: `"$var"`
- Use `[[ ]]` for conditionals, not `[ ]`
- ShellCheck clean — no warnings
- Python: stdlib only, `ruff`-clean

## Reporting issues

Use the GitHub issue templates under `.github/ISSUE_TEMPLATE/`. For security issues, see [SECURITY.md](SECURITY.md) — do not open a public issue.

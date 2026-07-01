# cast-ledger

Tamper-evident session receipts + optional provenance hash-chain over `cast.db`. Extracted from the [claude-agent-team](https://github.com/ek33450505/claude-agent-team) flagship's `cast ledger` / `cast verify-chain` / `cast provenance` commands.

## Layout

- `bin/cast-ledger` — bash launcher. Routes `provenance <sub>` / `verify-chain` / `version` / `help`; any other args pass through to the receipt renderer.
- `scripts/cast-ledger.py` — receipt renderer. Stdlib only, opens `cast.db` `mode=ro`.
- `scripts/cast-provenance-chain.py` — the hash-chain. Loads `cast-ledger.py` via importlib → BOTH scripts MUST install into the same lib dir.
- `install.sh` / `uninstall.sh` — launcher into `~/.local/bin`, both scripts into `~/.local/lib/cast-ledger`.
- `tests/cast-ledger.bats` — isolated-temp-HOME BATS suite.

## Invariants (do not break)

- **Receipts are read-only.** The renderer opens `mode=ro`. Only the provenance chain writes, and ONLY to its own `provenance_chain` table.
- **Digest stability is a contract.** `_compute_digest` / `_build_receipt_data` define what a receipt commits to. Any change breaks `--verify` on old receipts → breaking change, bump version.
- **Integrity export is safe-only.** Never export a raw agent-output/freetext column (`_INTEGRITY_FREETEXT_COLS` allow-list-out).
- **Self-create the chain table.** Standalone has no `cast-db-init.sh`, so the append path runs `CREATE TABLE IF NOT EXISTS provenance_chain` (idempotent). verify/status treat a missing chain table as an empty chain, not an error.
- **Stdlib only. Local-only.** No `pip install`, no network, no external anchor.
- **No PII in the repo.** Paths in docs/tests are `~/` / `/Users/you/` placeholders — never real home paths, never real session IDs or `cast.db` contents.

## Test

```bash
bats tests/        # isolated temp HOME
bash -n bin/cast-ledger install.sh uninstall.sh
ruff check scripts/
```

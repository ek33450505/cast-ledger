# Changelog

## [0.1.0] — 2026-07-01

Initial release. Extracted from [claude-agent-team](https://github.com/ek33450505/claude-agent-team) v9's `cast ledger` / `cast verify-chain` / `cast provenance` commands.

### Added
- Standalone `cast-ledger` launcher: receipts by default, `provenance <append|verify|backfill|status>`, `verify-chain` alias, `version` / `help`.
- **Receipt renderer** (`cast-ledger.py`) over `cast.db` (opened `mode=ro`):
  - SHA-256-stamped, deterministic canonical digest
  - Markdown or `--json` output; `--out FILE`
  - Session selection: `SESSION_ID`, `--last N`, `--since DATE`, or default (most recent)
  - `--verify FILE` re-derives the digest and reports `PASS` / `TAMPERED` (non-zero exit on tamper)
  - Sections: Session, Models & Cost, Agents, Files Changed, Decisions & Gates, Integrity
  - Integrity export is safe-columns-only — raw agent-output/freetext columns are never included
- **Provenance chain** (`cast-provenance-chain.py`): tamper-evident hash-chain of per-session digests
  - `append` / `verify` / `backfill` / `status`
  - `chain_hash = sha256(prev_hash + session_digest)`; two-level verify (linkage + session attestation)
  - Self-creates the `provenance_chain` table on first append (standalone has no `cast-db-init.sh`)
  - Read-only against session data; writes only to its own chain table
- Idempotent `install.sh` / `uninstall.sh` — launcher into `~/.local/bin`, scripts into `~/.local/lib/cast-ledger`
- `CAST_DB_PATH` / `CAST_LEDGER_LIB` env overrides

### Notes
- Python 3 stdlib only — no `pip install`
- Local-only: no network, no external anchor (see SECURITY.md for chain trust-model limitations)

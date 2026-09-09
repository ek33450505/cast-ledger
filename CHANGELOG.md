# Changelog

## [0.2.0] — 2026-09-09

Sync with `claude-agent-team` v10.1.0. Fixes a defect that made every receipt
under-report its agent runs.

### Fixed
- **Receipts reported zero agent runs.** `cast-ledger.py` selected `owns_files`,
  a column dropped from `agent_runs` upstream. The bare
  `except sqlite3.OperationalError: return []` swallowed the error, so receipts
  rendered successfully while claiming the session had no agents. Verified
  against a copy of a live `cast.db`: 0 reported vs 368 actual.
- The test fixture created `agent_runs` *with* `owns_files`, mirroring the stale
  query rather than the real schema — which is why CI never caught this. The
  fixture now mirrors the current schema, and a new test asserts the agent-run
  count rather than only the receipt header.

### Added
- `receipt_json` (upstream PROV-1): the exact canonical serialization the
  `session_digest` was taken over is now persisted with each chain row. A digest
  over inputs that keep moving — retention prunes `agent_runs`, and cost/token
  columns are backfilled after a session ends — cannot otherwise be re-derived.
- `canonical_json()` and `digest_of_canonical_json()` in `cast-ledger.py`.
- Self-healing `ALTER` so a standalone `provenance_chain` created before
  `receipt_json` gains the column. `CREATE TABLE IF NOT EXISTS` is a no-op on an
  existing table, so without this the append succeeds but stores no payload.
- `quality_gates` reads now exclude truncation-mirror rows (`status_line='TRUNCATED'`).

### Notes
- The standalone adaptations are preserved: `_ensure_chain_schema()` provisions
  the chain table (standalone has no `cast-db-init.sh`), and `verify` / `status`
  still treat an absent chain table as "never initialized" rather than an error.

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

# cast-ledger

**Tamper-evident audit receipts for your Claude Code sessions.** cast-ledger renders a human-readable, **SHA-256-stamped** receipt of what happened in a session — models, cost, agents, files changed, routing decisions, quality gates, and integrity events — entirely from your local `cast.db`. Re-run it with `--verify` and it re-derives the digest to prove the receipt (and the underlying record) wasn't altered.

Add the optional **provenance chain** and each session's digest is linked into a hash-chain, so insertion, deletion, reordering, or modification of any past session is detectable.

- **Strictly read-only receipts.** `cast.db` is opened `mode=ro`; rendering never writes.
- **Deterministic digest.** The receipt digest is a canonical SHA-256 over the session's data — same data, same digest, on any machine.
- **Local-only.** No network, no external anchor, no telemetry. Nothing leaves your machine.
- **Zero dependencies.** Python 3 stdlib only — no `pip install`.

Works **without** the full CAST framework. Point it at any `cast.db`.

## Install (Homebrew)

```bash
brew tap ek33450505/cast-ledger && brew install cast-ledger
```

## Manual install

```bash
git clone https://github.com/ek33450505/cast-ledger.git
cd cast-ledger
bash install.sh
```

`install.sh` copies the `cast-ledger` launcher into `~/.local/bin` and the two scripts into `~/.local/lib/cast-ledger/`. Idempotent — safe to re-run.

## Usage

### Receipts

```bash
cast-ledger                      # receipt for the most recent session
cast-ledger <SESSION_ID>         # receipt for a specific session
cast-ledger --last 5             # the 5 most-recent sessions
cast-ledger --since 2026-07-01   # every session since a date
cast-ledger --json               # machine-readable JSON (with digest)
cast-ledger --out receipt.md     # write to a file instead of stdout
cast-ledger --verify receipt.md  # re-derive the digest and check for tampering
```

A receipt ends with a line like:

```
---
Digest: sha256:9f2c…<64 hex>
```

`--verify` re-reads the session from `cast.db`, recomputes the digest, and prints `VERIFY: PASS` or `VERIFY: TAMPERED (...)` — non-zero exit on tamper.

### Provenance chain (optional)

```bash
cast-ledger provenance backfill    # append every session to the chain (idempotent)
cast-ledger provenance append <SESSION_ID>
cast-ledger provenance status      # chain length, head hash, pruned attestations
cast-ledger provenance verify      # walk the chain, detect tampering
cast-ledger verify-chain           # alias for `provenance verify`
```

The chain stores each session's digest at append time, linked as `chain_hash = sha256(prev_hash + session_digest)`. On first use the `provenance_chain` table is created automatically.

**Trust model:** local-only, no external anchor. The chain detects insertion, deletion, reordering, or modification unless an attacker with full read-write access to `cast.db` consistently re-chains every subsequent link. Closing that requires publishing the head hash to an append-only/remote store — out of scope for a local tool. Pruned sessions (removed from `cast.db`) keep their stored digest in the chain but can no longer be re-derived; `verify` reports them as pruned-skipped.

## What's in a receipt

| Section | Content |
|---|---|
| Session | id, project, started/ended, duration, status |
| Models & Cost | distinct models, input/output/cache tokens, total USD |
| Agents | per-agent model, status, duration, cost, tool uses |
| Files Changed | file, tool, agent |
| Decisions & Gates | routing events + quality-gate pass/retry |
| Integrity | protocol violations, hallucinations, truncations, completeness flags (counts + safe descriptors only) |

The integrity export is **safe-columns-only** — raw agent-output / freetext columns (excerpts, work logs, prompts) are never included in a portable receipt.

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `CAST_DB_PATH` | `~/.claude/cast.db` | Path to the record database |
| `CAST_LEDGER_LIB` | *(auto-resolved)* | Override the scripts dir (advanced/dev use) |

## Security

- Receipt rendering opens `cast.db` read-only (`mode=ro`).
- Digests are SHA-256 over a canonical JSON serialization — deterministic and collision-resistant.
- The provenance chain writes ONLY to its own `provenance_chain` table (created idempotently); it never mutates session data and reads the source via a read-only connection.

See [SECURITY.md](SECURITY.md) for the full trust model and known limitations.

## Requirements

- **Python 3** (stdlib only)
- **sqlite3**
- A `cast.db` (created by [claude-agent-team](https://github.com/ek33450505/claude-agent-team) or any CAST tool)

## Part of the CAST ecosystem

Extracted from [claude-agent-team](https://github.com/ek33450505/claude-agent-team)'s `cast ledger` / `cast verify-chain` / `cast provenance` commands.

<!-- ECOSYSTEM_START -->
| Repo | Description | Install |
|---|---|---|
| [claude-agent-team](https://github.com/ek33450505/claude-agent-team) | The CAST flagship — the local, inspectable, tamper-evident record of what your agents did. | `git clone` |
<!-- ECOSYSTEM_END -->

## License

[MIT](LICENSE) © Edward Kubiak

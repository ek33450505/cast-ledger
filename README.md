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
**Core Framework**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-agent-team](https://github.com/ek33450505/claude-agent-team) | Local-first multi-agent control plane — specialist agents, quality gates, hook enforcement, and the tamper-evident cast.db execution record. | ![](https://img.shields.io/github/v/release/ek33450505/claude-agent-team?style=flat-square) | `brew tap ek33450505/cast && brew install cast` |

**Observability**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-code-dashboard](https://github.com/ek33450505/claude-code-dashboard) | React observability UI — sessions, agent analytics, hook health, memory browser, SQLite explorer. | ![](https://img.shields.io/github/v/release/ek33450505/claude-code-dashboard?style=flat-square) | Clone from GitHub |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, 11 dashboard views. | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |

**Standalone Packages**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-mcp](https://github.com/ek33450505/cast-mcp) | Read-only MCP server over the Claude Code execution record (cast.db) — dispatch decisions, incidents, cost, sessions, and full-text search as 5 MCP tools + 5 resources. stdlib-only, strictly read-only. | ![](https://img.shields.io/github/v/release/ek33450505/cast-mcp?style=flat-square) | `brew tap ek33450505/cast-mcp && brew install cast-mcp` |
| [cast-ledger](https://github.com/ek33450505/cast-ledger) | Signed, hash-chained, tamper-evident session receipts for Claude Code — SHA-256-stamped audit receipts from cast.db with `--verify`, plus an optional provenance hash-chain across sessions. | ![](https://img.shields.io/github/v/release/ek33450505/cast-ledger?style=flat-square) | `brew tap ek33450505/cast-ledger && brew install cast-ledger` |
| [cast-predict](https://github.com/ek33450505/cast-predict) | Telemetry-driven dispatch prediction for Claude Code — reads cast.db to predict a task's likely cost, suggest agents, and surface related past incidents before you run it. | ![](https://img.shields.io/github/v/release/ek33450505/cast-predict?style=flat-square) | `brew tap ek33450505/cast-predict && brew install cast-predict` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory for Claude Code — FTS5 full-text search, weighted relevance, temporal validity, Ollama embeddings, and weekly consolidation over cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Standalone read-only health check for any Claude Code install — validates hooks, MCP config, agent frontmatter, cast.db core schema, and stale memories without the full CAST framework. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Three-hook journaling for Claude Code (Stop/SessionStart/UserPromptSubmit) — maintains Claude's perspective and working memory across sessions as Obsidian-compatible markdown in ~/Documents/Claude/. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
<!-- ECOSYSTEM_END -->

## License

[MIT](LICENSE) © Edward Kubiak

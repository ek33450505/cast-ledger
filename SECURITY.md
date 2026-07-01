# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.1.x | Full support — security fixes backported |
| < 0.1 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-ledger/security/advisories/new).

### What to Include

- **Version** — `cast-ledger version`
- **Operating system** — `sw_vers` (macOS) or `lsb_release -a` (Linux)
- **Which surface** — e.g., the receipt renderer, `--verify`, `provenance verify`
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

- **Read-only receipts** — the receipt renderer opens `cast.db` with the SQLite URI `mode=ro`. It can never write to the record.
- **Deterministic digest** — the receipt digest is `sha256` over a canonically-serialized (sorted-key, compact) JSON of the session's data. The same data yields the same digest on any machine, which is what makes `--verify` meaningful.
- **Safe integrity export** — integrity tables (protocol violations, hallucinations, truncations, completeness) are exported as counts + safe descriptor columns only. Raw agent-output / freetext columns (excerpts, work logs, prompts, stdout/stderr) are allow-listed OUT and never appear in a portable receipt.
- **Provenance writes are scoped** — the provenance chain writes ONLY to its own `provenance_chain` table (created idempotently via `CREATE TABLE IF NOT EXISTS`). It reads session data through a separate read-only connection and never mutates it. Appends use `BEGIN IMMEDIATE` + `INSERT OR IGNORE` for concurrency safety and idempotency.
- **Parameterized queries** — no user input is interpolated into SQL. Integrity table names are validated against a frozen allow-list before use.
- **Fail-open reads** — every section collector is wrapped so a missing table or column degrades to an empty section rather than crashing.

## Chain Trust Model — Known Limitations

The provenance chain is **local-only with no external anchor**. It detects insertion, deletion, reordering, or modification of chain rows / session data **unless** the attacker performs a full consistent re-chain.

- **Limitation 1:** An attacker with full read-write access to `cast.db` can edit a `session_digest` and recompute every subsequent `chain_hash` consistently. Closing this requires publishing the head `chain_hash` to an append-only / remote / WORM store — out of scope for a local tool.
- **Limitation 2:** Deleting a session row makes `verify` classify that link as "pruned" and skip re-derivation; the `chain_hash` still locks the stored digest, but it can no longer be independently re-derived. Pruning is by design (the chain stores the digest at append time to survive TTL pruning).
- **Limitation 3:** Truncating the chain tail leaves a valid prefix; only the empty-chain case is cross-checked against the session count.

These limitations are inherent to a local, un-anchored chain and are documented, not hidden.

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (bash, Python, sqlite3, BATS)
- The contents of `~/.claude/cast.db` — a user-controlled input the tool only reads (except the tool's own `provenance_chain` table)

## Trust Model

cast-ledger assumes the user controls `~/.claude/`, the `sqlite3` library and Python interpreter are trustworthy, and `cast.db` is trusted input. cast-ledger uses stdlib only.

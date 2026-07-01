#!/usr/bin/env bats
# tests/cast-ledger.bats — Isolated integration tests for cast-ledger CLI.
# HARD RULE: real ~/.claude is NEVER touched. All DB + HOME activity is isolated to temp dirs.

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CLI="$REPO_DIR/bin/cast-ledger"

setup() {
  _ORIG_HOME="$HOME"
  HOME="$(mktemp -d)"
  export HOME
  mkdir -p "$HOME/.claude"
  export CAST_DB_PATH="$BATS_TEST_TMPDIR/test-ledger-$$.db"
  export CAST_LEDGER_LIB="$REPO_DIR/scripts"
}

teardown() {
  rm -f "$CAST_DB_PATH"
  rm -rf "$HOME"
  HOME="$_ORIG_HOME"
  export HOME
}

_make_db() {
  command -v sqlite3 >/dev/null || skip "sqlite3 not available"
  sqlite3 "$CAST_DB_PATH" "
CREATE TABLE sessions(id TEXT, project TEXT, project_root TEXT, started_at TEXT, ended_at TEXT, status TEXT);
CREATE TABLE agent_runs(session_id TEXT, agent TEXT, model TEXT, status TEXT, started_at TEXT, ended_at TEXT, input_tokens INTEGER, output_tokens INTEGER, cost_usd REAL, cache_read_input_tokens INTEGER, cache_creation_input_tokens INTEGER, owns_files TEXT, duration_ms INTEGER, tool_uses INTEGER);
INSERT INTO sessions VALUES('sess-test-1','demo','/tmp/demo','2026-07-01T10:00:00','2026-07-01T10:30:00','completed');
INSERT INTO agent_runs VALUES('sess-test-1','code-writer','claude-opus-4-8','DONE','2026-07-01T10:01:00','2026-07-01T10:05:00',100,200,0.05,10,5,'',240000,7);
"
}

# 1. CLI is executable
@test "CLI is executable" {
  [ -x "$CLI" ]
}

# 2. version exits 0 and contains cast-ledger v
@test "version subcommand exits 0 and prints version" {
  run bash "$CLI" version
  [ "$status" -eq 0 ]
  [[ "$output" == *"cast-ledger v"* ]]
}

# 3. help exits 0 and contains Usage:
@test "help subcommand exits 0 and prints usage" {
  run bash "$CLI" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

# 4. CLAUDE_SUBPROCESS=1 exits 0 with empty output
@test "CLAUDE_SUBPROCESS=1 exits immediately with no output" {
  run env CLAUDE_SUBPROCESS=1 bash "$CLI" version
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# 5. receipt render contains header + digest
@test "receipt render for a known session_id exits 0 and contains receipt header" {
  _make_db
  run bash "$CLI" sess-test-1
  [ "$status" -eq 0 ]
  [[ "$output" == *"CAST Session Receipt"* ]]
  [[ "$output" == *"Digest: sha256:"* ]]
}

# 6. --json output is valid JSON with expected structure
@test "--json produces valid JSON with correct session id and sha256 digest" {
  _make_db
  run bash "$CLI" sess-test-1 --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['digest'].startswith('sha256:'), f'bad digest: {d[\"digest\"]}'
assert d['receipt']['session']['id'] == 'sess-test-1', f'bad id: {d[\"receipt\"][\"session\"][\"id\"]}'
"
}

# 7. --last 1 renders a receipt
@test "--last 1 exits 0 and renders a receipt" {
  _make_db
  run bash "$CLI" --last 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"CAST Session Receipt"* ]]
}

# 8. verify PASS roundtrip
@test "verify --verify on a freshly written receipt exits 0 with VERIFY: PASS" {
  _make_db
  bash "$CLI" sess-test-1 --out "$BATS_TEST_TMPDIR/r.md"
  run bash "$CLI" --verify "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"VERIFY: PASS"* ]]
}

# 9. verify TAMPERED — corrupt the digest and expect non-zero + TAMPERED
@test "verify detects tampered receipt and exits non-zero" {
  _make_db
  bash "$CLI" sess-test-1 --out "$BATS_TEST_TMPDIR/r.md"
  # Read the original digest line
  orig_digest=$(grep '^Digest: sha256:' "$BATS_TEST_TMPDIR/r.md" | head -1)
  # Corrupt by changing the first hex char after 'sha256:'
  # sed on macOS requires explicit backup extension
  python3 -c "
import re, sys
content = open('$BATS_TEST_TMPDIR/r.md').read()
# Replace first hex char of the sha256 digest with a different one
def corrupt(m):
    prefix, first, rest = m.group(1), m.group(2), m.group(3)
    # Flip first char: if '0'-'9' bump to 'a', else '0'
    replacement = 'a' if first.isdigit() else '0'
    return prefix + replacement + rest
corrupted = re.sub(r'(Digest: sha256:)([0-9a-f])([0-9a-f]+)', corrupt, content, count=1)
assert corrupted != content, 'corruption did not change the content'
open('$BATS_TEST_TMPDIR/r.md', 'w').write(corrupted)
"
  run bash "$CLI" --verify "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"TAMPERED"* ]]
}

# 10. provenance status on fresh db (no chain table) exits 0 with Chain length: 0
@test "provenance status on a fresh db (no chain table) exits 0 with Chain length: 0" {
  _make_db
  run bash "$CLI" provenance status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Chain length:"* ]]
  [[ "$output" == *"0"* ]]
}

# 11. provenance backfill creates table and fills it
@test "provenance backfill creates provenance_chain table and fills it" {
  _make_db
  run bash "$CLI" provenance backfill
  [ "$status" -eq 0 ]
  [[ "$output" == *"BACKFILL:"* ]]
  run bash -c "sqlite3 \"$CAST_DB_PATH\" '.tables'"
  [[ "$output" == *"provenance_chain"* ]]
}

# 12. provenance verify PASS after backfill
@test "provenance verify exits 0 with VERIFY-CHAIN: PASS after backfill" {
  _make_db
  bash "$CLI" provenance backfill
  run bash "$CLI" provenance verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"VERIFY-CHAIN: PASS"* ]]
}

# 13. verify-chain alias works
@test "verify-chain alias is equivalent to provenance verify" {
  _make_db
  bash "$CLI" provenance backfill
  run bash "$CLI" verify-chain
  [ "$status" -eq 0 ]
  [[ "$output" == *"VERIFY-CHAIN: PASS"* ]]
}

# 14. chain tamper detected
@test "provenance verify detects a tampered chain row and exits non-zero" {
  _make_db
  bash "$CLI" provenance backfill
  sqlite3 "$CAST_DB_PATH" "UPDATE provenance_chain SET session_digest='sha256:deadbeef' WHERE seq=1;"
  run bash "$CLI" provenance verify
  [ "$status" -ne 0 ]
  [[ "$output" == *"BROKEN"* ]]
}

# 15. append is idempotent — second append exits 0, chain length stays 1
@test "provenance append is idempotent: double-append keeps chain length at 1" {
  _make_db
  bash "$CLI" provenance append sess-test-1
  run bash "$CLI" provenance append sess-test-1
  [ "$status" -eq 0 ]
  run bash "$CLI" provenance status
  [[ "$output" == *"Chain length:"* ]]
  [[ "$output" == *"1"* ]]
}

# 16. bin/cast-ledger passes bash -n
@test "bin/cast-ledger has no bash syntax errors" {
  run bash -n "$REPO_DIR/bin/cast-ledger"
  [ "$status" -eq 0 ]
}

# 17. install.sh passes bash -n
@test "install.sh has no bash syntax errors" {
  run bash -n "$REPO_DIR/install.sh"
  [ "$status" -eq 0 ]
}

# 18. uninstall.sh passes bash -n
@test "uninstall.sh has no bash syntax errors" {
  run bash -n "$REPO_DIR/uninstall.sh"
  [ "$status" -eq 0 ]
}

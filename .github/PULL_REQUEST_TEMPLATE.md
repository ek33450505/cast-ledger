## Description

<!-- What does this PR change and why? -->

## Checklist

- [ ] `bash install.sh && bash uninstall.sh` round-trip clean
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash -n bin/cast-ledger install.sh uninstall.sh` — all syntax-check
- [ ] `cast-ledger --quick` and `cast-ledger --json` both work
- [ ] No writes to disk anywhere — cast-ledger is strictly read-only
- [ ] No hardcoded paths — `$HOME` / `~/` used
- [ ] `CHANGELOG.md` updated for user-visible changes

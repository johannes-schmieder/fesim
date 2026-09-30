# CI and exact-source qualification

## GitHub-hosted checks

`.github/workflows/static.yml` runs on pushes, pull requests, and manual
dispatch with read-only repository permissions. It uses a GitHub-hosted Ubuntu
runner and the Python standard library. It checks whitespace/artifact hygiene,
installation manifest and version consistency, Mata and test registration,
runtime dependencies, executable help markers/navigation, current source and
calibration inventories, documentation paths, and exact-SHA receipt verification.

The job is labeled `no Stata`: it does not install, emulate, or invoke Stata.
**No personal self-hosted runner belongs on this repository.** Licensed automation
must stay local or in a separate trusted private CI repository.

## Licensed local tests

```sh
STATA_BIN=/path/to/stata-mp scripts/run_stata_tests.sh
```

The wrapper refuses source changes, derives the exact `HEAD` and branch, runs
`tests/run_all.do`, and invokes `scripts/verify_stata_receipt.py`. Acceptance
requires the exact SHA, clean worktree, correct filename/repository/branch,
accepted status, zero exit/failure counts, complete registered test inventory,
per-test PASS markers, and a clean Mata rebuild. Receipts and logs remain ignored
local evidence. See [validation](validation.md).

## Owner-controlled Windows entry point

`windows-ci.do` invokes the full suite and writes ignored `windows-ci.status`
only after success. It is a portable local batch entry point and contains no
runner registration or credentials. External Windows qualification binds the
marker to exact source/archive hashes and licensed Stata logs. This file alone
does not establish current Windows support.

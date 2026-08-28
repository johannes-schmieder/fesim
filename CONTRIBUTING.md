# Contributing to fesim

`DESIGN.md` is the normative architecture and public-interface contract. `PLAN.md` is the live execution and evidence ledger. Read both completely before implementation work.

## Development rules

- Work directly on `main` unless the owner changes the branch policy.
- Pull with `--ff-only` before starting and before pushing when the remote may have changed.
- Keep commits small, coherent, tested, and paired with the relevant `PLAN.md` update.
- Keep every installed runtime path pure Stata/Mata. Repository-only static tooling may use other languages, but users must not need it.
- Do not commit logs, datasets, scratch files, generated Mata libraries, credentials, or machine-specific executable paths.
- Do not advertise a DGP, preset, Stata version, or platform as qualified without exact-source test evidence.

## Build

From the repository root in Stata:

```stata
do src/build_mlib.do
```

The command rebuilds the development `lfesim.mlib` into the ignored `build/` directory and verifies that its minimal API can be loaded. Mata source files are authoritative. Whether a compiled library ships in releases remains an open design gate.

## Tests

The single Stata entry point is:

```stata
do tests/run_all.do
```

It rebuilds the Mata library, performs a clean temporary package installation, and runs the smoke, parser, failure-mode, and state-preservation tests. When invoked outside the repository root, pass the repository path as the first argument.

Inspect the complete batch and per-test logs under the ignored `build/test-results/` directory. A zero process exit alone is not sufficient evidence if a log contains an unexpected Stata error or skipped test.

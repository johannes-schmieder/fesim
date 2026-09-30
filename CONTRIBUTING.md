# Contributing to fesim

Start with the [public interface contract](docs/interface.md), the relevant
model note, and the installed help. The [architecture guide](docs/architecture.md)
maps source files to their responsibilities.

## Development rules

- Work directly on `main` unless the owner changes the branch policy. Pull with
  `--ff-only` before starting and before pushing when the remote may have changed.
- Keep commits small, coherent, and tested. Document user-visible changes in
  `CHANGELOG.md`; keep current interface and source inventories consistent.
- Every installed file basename must start with `fesim` for SSC file hosting.
  Use `fesim__*` for internal autoload helpers; keep filenames, program names,
  callers and the package manifest aligned. This includes Mata, help and assets.
- Keep installed runtime paths pure official Stata/Mata. Repository-only tools
  may use other languages, but users must not need them.
- Preserve caller data/RNG on failure, fixed-seed truth/block invariance, and
  scientific units, sample rules, and calibration boundaries.
- Do not commit logs, datasets, generated Mata libraries, scratch files,
  credentials, license material, or machine-specific executable paths.
- Do not advertise a model, platform, or Stata version as tested without
  exact-source evidence. Keep accepted receipts and raw logs outside tracked source.
- Keep licensed tests local or in a separate trusted private CI repository.
  **Never attach a personal self-hosted runner to this public source repository.**

## Build and tests

Users install the authoritative Mata source; a compiled library is not required.
For development, rebuild the ignored library from the repository root in Stata:

```stata
do src/build_mlib.do
```

The complete test entry point is:

```stata
do tests/run_all.do
```

It rebuilds Mata, performs a clean temporary installation, and runs all
registered unit, integration, deterministic regression, statistical, and
executable documentation suites. It isolates `PERSONAL` and `PLUS` so a stale
installation cannot satisfy the tests. Pass the repository path as argument 1
when invoking it outside the root. Inspect the batch and per-test logs in the
ignored `build/test-results/`; a zero OS exit alone does not establish success.

For an exact-source receipt from a clean checkout:

```sh
STATA_BIN=/path/to/stata-mp scripts/run_stata_tests.sh
```

The wrapper derives `HEAD` and verifies source, branch, clean worktree, test
inventory, per-test success, and the Mata rebuild. See [CI](docs/ci.md) and
[qualification](docs/validation.md).

GitHub-hosted CI runs these dependency-free static checks:

```sh
python3 scripts/static_checks.py
python3 -m unittest discover -s tests/static -p 'test_*.py' -v
```

A green static job is separate from licensed Stata testing. Performance harnesses
are documented in [tests/performance](tests/performance/README.md). Manual source,
figures, and their regeneration scripts live under `docs/`; example scripts are
part of the Stata suite.

## Release qualification

Run the full suite from exact clean source and, for a packaged release, again
from an isolated source archive. Preserve receipts and checksums, verify the
installation manifest, examples, manual, platform scope, scientific claims,
and matched deterministic/performance controls as relevant. See
[publishing](docs/publishing.md). Do not rewrite existing tags; a source cleanup
or public visibility change does not itself create a new software release.

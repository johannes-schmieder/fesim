# Validation and supported environments

The current source is `1.2.0-rc.1`, requiring Stata 19 or later. Full licensed
qualification has covered Stata/MP 19 on macOS Apple Silicon. Linux, Windows,
Stata/SE, and Stata 16–18 are not qualified for this candidate. The older
simple-AKM `v0.1.0` tag was also qualified on Windows x86-64; that evidence
does not extend to later model families.

## What is tested

The full runner contains 73 Stata files, covering source-only installation of
all ten presets, unit and independent scientific checks, public integration,
frozen deterministic fixtures, statistical moments, transactional failures,
caller data/RNG, block/truth/frequency invariants, 22 clickable help examples,
and fourteen standalone manual scripts. The source inventory is in
[interface](interface.md), and [tests](../tests/README.md) describes the suites.

The BLM candidate preserved all 46 pre-BLM deterministic legacy/CPV performance
controls and passed 20 BLM scaling cases. Same-host repeated comparisons resolved
two initial performance outliers. Benchmarks are descriptive measurements;
see [performance](performance.md).

## SSC filename qualification — 2026-09-30

All 73 licensed Stata files passed on exact clean source
`8ebb94b707a6b4d666b3c019508c3134f3d2787f` with Stata/MP 19 on macOS Apple
Silicon. The source-only installation covers all ten presets and an older Mata
file earlier on adopath, verifying that the renamed `fesim__*` loader selects
its adjacent installed sources. All 49 installed basenames start with `fesim`.
Ten static checks and sixteen Python tests passed; packaging tests reject
unprefixed ado, help and Mata files.

Accepted receipt SHA-256:
`8833b2d9a381fa1841407fc413f056590f1a1582573fa6552e8ef63ae00f9964`.
The subsequent documentation-only commit records this run and corrects the
manual's inventory and cleaned benchmark reference. Runtime, manifest, tests
and examples are identical to the exact tested source above.

## History-cleanup qualification — 2026-09-30

The complete licensed suite passed on exact clean source
`e0bf2de0e22e2d2e37c0c7e3377b856facf73788` after the repository history cleanup:
all 73 Stata files, including ten-preset source installation, all 22 clickable
help examples, and fourteen manual scripts. Ten static contract checks and
fourteen Python tests also passed.

The public-source preparation additionally passed seven noninstallation README
Stata blocks verbatim and translated the revised help through Stata's SMCL
renderer. The installed ado/Mata sources, Stata tests/examples, package manifest,
and manual are unchanged by preparation and history cleanup. Obsolete planning
and review records were removed from all published branches and tags; retained
source trees were checked against the original revisions.

A later documentation-only commit records this qualification and updates
benchmark source references. The accepted receipt remains bound to the exact
tested source above; historical receipts retain their original source IDs in
private archives.

## Reproduce a qualification

From a clean checkout:

```sh
STATA_BIN=/path/to/stata-mp scripts/run_stata_tests.sh
```

The wrapper derives the exact SHA, rebuilds Mata, runs the complete registered
inventory, and verifies the generated receipt and per-test success logs.
Accepted receipts and raw logs remain local under ignored `build/test-results/`.
A stale receipt, incomplete inventory, dirty source, or missing PASS marker is
an error. GitHub-hosted static checks establish source consistency separately;
they do not execute licensed Stata.

For an isolated archive, use `scripts/qualify_archive.py` as described in
[publishing](publishing.md). Record the exact SHA, archive/receipt checksums,
Stata version/flavor/revision, OS, and architecture with every qualification.

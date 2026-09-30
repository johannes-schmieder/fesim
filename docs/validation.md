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

Licensed tests passed on exact source
`be1ef898c545982022054a86a9bb1c9991667d03` on 2026-09-12. That maintenance
source preserved the installed runtime and manual of the BLM candidate
`3f9bb87ecb4ddbde2f9b093da0cfa0d27ec61c86`, whose full suite also passed in
an isolated source archive on 2026-09-06. These are historical tested source
identities; they must not be relabeled as qualification of later commits.

The BLM candidate preserved all 46 pre-BLM deterministic legacy/CPV performance
controls and passed 20 BLM scaling cases. Same-host repeated comparisons resolved
two initial performance outliers. Benchmarks are descriptive measurements;
see [performance](performance.md).

## Public-source documentation checks — 2026-09-30

The complete licensed suite passed on exact clean preparation source
`4b4088abb30cb56ebcf6a7a46abe78c4d810c710`: all 73 Stata files, including ten-preset
source installation, all 22 revised clickable help examples, and fourteen
manual scripts. Seven noninstallation README Stata blocks also passed verbatim;
the revised help translated successfully through Stata's SMCL renderer.
Ten static contract checks and fourteen Python tests passed separately.

The installed ado/Mata sources, Stata tests/examples, package manifest, and
manual are unchanged from `8c75e87`; this preparation reorganizes documentation
and replaces obsolete handover checks. A documentation-only follow-up records
this tested SHA and corrects the historical BM benchmark source attribution.
The receipt identifies its tested source, not that later documentation commit.

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

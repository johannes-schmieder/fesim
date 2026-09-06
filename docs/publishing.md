# Candidate qualification and publishing

`1.1.0-rc.1` is a development candidate for owner review. This work prepares an
unpublished exact-source archive. It does not create a tag, GitHub release, or
SSC submission. The stable release remains `v0.1.0`; current qualification is
Stata/MP 19 on macOS Apple Silicon. Windows, Linux, and SE require new receipts
before claiming support for this candidate.

## Reproduce the candidate

Build the manual with `bash docs/build_manual.sh`, render and inspect it, and
commit the finished source and documentation before exact qualification.
Start from that clean committed checkout. Set `STATA_BIN` to the local licensed
Stata executable; never commit machine-specific paths. From the repository root:

```sh
python3 scripts/static_checks.py
python3 -m unittest discover -s tests/static
bash scripts/run_stata_tests.sh "$STATA_BIN" full
python3 scripts/qualify_archive.py . "$STATA_BIN" build/release-review
python3 scripts/run_release_benchmarks.py . "$STATA_BIN" build/release-benchmarks
python3 scripts/run_cpv_benchmarks.py . "$STATA_BIN" build/cpv-benchmarks
```

The source wrapper removes stale receipts, rebuilds Mata, installs into isolated
PERSONAL/PLUS directories, runs the entire registered inventory, and verifies
its receipt against clean HEAD. `quick` and `full` currently select the same
inventory; the label does not imply a smaller test set.

The archive script refuses dirty source and a reused output directory. It runs
`git archive` on exact HEAD, extracts without `.git`, and reruns the full suite,
including source-only installation and all eight presets outside the checkout.
The outer `archive-receipt.json` binds source SHA, archive SHA-256, suite receipt,
file hashes, inventory, and environment. It explicitly does not use the
checkout-only Git verifier to certify the extraction. Generated libraries and
logs remain under ignored `build/`; only official Stata/Mata are installed.

For performance, compare identical harness/driver inputs against the recorded
pre-CPV source `1064f10`, including all six legacy presets, three AKM network designs, BM
scale, and private event recording. Compare `runtime_total` (or the BM driver's
corresponding measured elapsed time) and peak RSS per case. Investigate any
increase over 10% with three matched repetitions on both revisions; report
medians and retain raw results. Data signatures must be unchanged when no
simulation change is intended. The separate 20-case CPV harness measures worker,
firm, truth and frequency scaling. See [the candidate report](qualification-1.1.0-rc.1.md)
for accepted results and repeat investigations. Timing is descriptive, not a portable guarantee.

Render and inspect the rebuilt PDF, verify links and version consistency, and
record manual/archive/receipt hashes in the review report. An evidence-only
follow-up commit may record the qualified candidate SHA without relabeling its
archive as that later commit. Record local and hosted CI separately.

## Installation channels

Stable users can install the immutable `v0.1.0` source:

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/v0.1.0") replace
```

Development users can replace the URL suffix with `main`. `main` is mutable;
record its exact commit for research reproducibility. For the candidate, extract
the review archive and use `net install fesim, from("/path/to/extracted/source") replace`.
Check `fesim version` and `fesim describe` after installation. Source loading
builds the runtime in the user's official Stata/Mata session.

## Owner release gate

Review scientific claim boundaries, API compatibility, full-suite evidence,
archive installation, platform scope, performance comparison, and manual. Only
a separate release instruction authorizes an immutable candidate/stable tag and
GitHub release. At that point rerun qualification if the source changed, ensure
the tag resolves to the accepted SHA, publish release notes and installation
instructions, and attach the exact archive/checksums. Do not rewrite existing
tags. Consider SSC only after a stable GitHub release and separate authorization.

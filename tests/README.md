# Stata tests

Run the complete current suite from the repository root:

```stata
do tests/run_all.do
```

For an exact-source qualification receipt, pass the 40-character Git SHA, suite name, and branch:

```stata
do tests/run_all.do "/path/to/fesim" "<exact-sha>" quick main
```

Successful qualified runs write an ignored JSON receipt under `build/test-results/`. Supplying a SHA asserts only what the caller requested, so qualification procedures must obtain it from the checked-out Git worktree and must run with no source modifications.

The runner rebuilds Mata source, performs a clean local package installation, and executes all currently registered test files. Generated logs, receipts, and installation files are written under ignored `build/` paths.

The current suite covers clean installation, source smoke behavior, parsing failures, registry metadata, configuration equivalence/validation/serialization, abstract Stata time normalization, annual and competing-risk probability conversion, typed lifecycle construction/validation and call isolation, common flow finalization and boundary semantics, integrated panel types/labels/time/truth/cleanup, metadata and returned-result contracts, report/noreport invariance, component RNG isolation, integration-level data/RNG preservation, and deterministic block-output equivalence. Test categories remain separated into unit, integration, statistical, regression, performance, and fixtures directories. Statistical and regression suites contain scope notes until simulation output exists; they are not reported as passing simulation tests.

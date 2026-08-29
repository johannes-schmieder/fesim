# Stata tests

Run the complete current suite from the repository root:

```stata
do tests/run_all.do
```

For an exact-source qualification receipt, pass the 40-character Git SHA, suite name, and branch:

```stata
do tests/run_all.do "/path/to/fesim" "<exact-sha>" quick main
```

Successful qualified runs write an ignored JSON receipt under `build/test-results/`. Supplying a SHA directly is a lower-level interface and asserts only what the caller requested. Exact qualification should instead use `scripts/run_stata_tests.sh`, which refuses a dirty checkout, derives the SHA and branch from Git, and verifies the resulting receipt against the same checkout.

The runner rebuilds Mata source, performs a clean local package installation, and executes all currently registered test files. Generated logs, receipts, and installation files are written under ignored `build/` paths.

The current suite covers clean installation, source smoke behavior, parsing failures, registry metadata, configuration equivalence/validation/serialization, abstract Stata time normalization, annual and competing-risk probability conversion, typed lifecycle construction/validation and call isolation, common flow and moment finalization, integrated panel types/labels/time/truth/cleanup, metadata and returned-result contracts, report/noreport invariance, component RNG isolation, integration-level data/RNG preservation, and deterministic block-output equivalence. Test categories remain separated into unit, integration, static, statistical, regression, performance, and fixtures directories. Statistical and regression suites contain scope notes until simulation output exists; they are not reported as passing simulation tests.

The dependency-free static lane is separate from Stata qualification:

```sh
python3 scripts/static_checks.py
python3 -m unittest discover -s tests/static -p 'test_*.py' -v
```

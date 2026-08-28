# Stata tests

Run the complete current suite from the repository root:

```stata
do tests/run_all.do
```

The runner rebuilds Mata source, performs a clean local package installation, and executes all six registered Checkpoint 2 test files. Generated logs and installation files are written under ignored `build/` paths.

The current suite covers clean installation, source smoke behavior, parsing failures, registry metadata, configuration equivalence/validation/serialization, and integration-level data/RNG preservation. Test categories remain separated into unit, integration, statistical, regression, performance, and fixtures directories. Statistical and regression suites contain scope notes until simulation output exists; they are not reported as passing simulation tests.

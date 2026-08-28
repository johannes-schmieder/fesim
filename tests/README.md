# Stata tests

Run the complete current suite from the repository root:

```stata
do tests/run_all.do
```

The runner rebuilds Mata source, performs a clean local package installation, and executes every registered Checkpoint 1 test. Generated logs and installation files are written under ignored `build/` paths.

Test categories are separated into smoke, unit/parser, integration/state-preservation, statistical, regression, and fixtures directories. Statistical and regression suites contain scope notes until simulation output exists; they are not reported as passing simulation tests.

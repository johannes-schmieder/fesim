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

The current suite covers clean installation, source smoke behavior, checkout-source precedence over stale installed Mata files, parsing failures, registry and calibration-table metadata, configuration equivalence/validation/serialization, abstract Stata time normalization, empirical hazard conversion, the analytical BM equilibrium and independent reservation residual, deterministic and random finite-firm BM constructions, exact discrete stationary employment, strict wage ties, finite-grid convergence, the exact continuous-time BM event clock, accepted and rejected offers, destruction, stable spells/durations, ledger replay, recording invariance and RNG isolation, shared weighted-random and current-excluding destinations, grouped stabilized UE/EE destinations and sorting, balanced isolated-stream network assignments, block-weighted common and excluded destinations, exact zero-bonus nesting for both public routes, block truth output, tied firm-wage midranks, exact ladder direction mixtures, boundary renormalization, ordinary within-direction weights, public ladder behavior in both AKM routes, typed lifecycle construction/validation and call isolation, the monthly empirical duration lifecycle and correlated mobility primitives, both public AKM handlers, monthly-to-output transition aggregation, year-valued duration returns, full empirical truth and alias equivalence, simple-AKM population/initialization/mobility/wages, common flow and moment finalization, bipartite components, observed firm-link weights, no-mover counts, articulation firms, graph-bridge links, KSS-aligned complete-worker-history deletion, complete-match firm-disconnection audits, stayer-leaf exclusions, empty and disconnected leave-out boundaries, a 10,000-worker iterative stress graph, largest-component filtering and retained-sample recomputation, integrated panel types/labels/time/truth/cleanup, metadata and returned-result contracts, report/noreport invariance, component RNG isolation, integration-level data/RNG preservation, deterministic block-output equivalence, frozen annual/quarter/month regression fixtures, large-sample statistical moments/exogeneity/sorting/duration behavior, runtime timer ownership, and executable documentation examples. Test categories remain separated into unit, integration, static, statistical, regression, performance, and fixtures directories. Performance receipts are produced separately by the clean benchmark harness.

The dependency-free static lane is separate from Stata qualification:

```sh
python3 scripts/static_checks.py
python3 -m unittest discover -s tests/static -p 'test_*.py' -v
```

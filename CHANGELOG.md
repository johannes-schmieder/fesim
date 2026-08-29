# Changelog

## 0.1.0 — 2026-08-29

### Implemented

- Public `dgp(akm) preset(simple)` simulation and the `dgp(akmsimple)` alias.
- Reproducible worker-period panels at annual, quarterly, and monthly output
  frequencies with isolated component RNG streams.
- Stylized worker and firm effects, exogenous mobility, unemployment, wages,
  burn-in, and basic/full/none truth-output modes.
- Common flow, wage, firm-size, concentration, mover/stayer, truth-component,
  and target-comparison results.
- Compressed observed worker-firm graph diagnostics and deterministic
  `connectivity(largest)` filtering that retains complete worker histories.
- Dataset metadata, public returned matrices, stage runtimes, tested examples,
  source-only package installation, and exact-source qualification tooling.
- Frozen deterministic fixtures, large-sample statistical tests, and public
  performance baselines through 1,000,000 workers and 10,000,000 rows.

The `akm/simple` defaults are a transparent stylized teaching and testing
design. They are not an empirical or paper calibration.

### Planned, not implemented in 0.1.0

- `akm/empirical` and the `akmempirical` alias.
- `akmpaygap/simple` and the CCK-inspired `akmpaygap/cck2016` preset.
- `bm/simple` and the `bmsimple` alias, pending an accepted equilibrium
  derivation.
- `connectivity(force)`, pending an accepted scientific generation rule.
- Cross-platform or cross-version bitwise reproducibility beyond the exact
  environments recorded in `PLAN.md`.

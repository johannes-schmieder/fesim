# fesim

`fesim` is a Stata/Mata package for simulating linked employer–employee panels. Its intended scope includes transparent AKM-style designs, mobility and network experiments, pay-gap decompositions, and later structural search models, all behind a common output contract.

The installed runtime will use only official Stata and Mata. It will not require a compiled plugin, Python, R, Julia, or a user-written Stata dependency.

## Current implementation status

The latest release is `v0.1.0`. The `main` branch is now `0.2.0-dev`, developing the generic empirical-mobility engine while retaining the released end-to-end stylized `akm/simple` simulator. Discovery, preset inspection, canonical alias resolution, and deterministic default reporting remain available:

```stata
fesim version
fesim list
fesim presets
fesim presets akm
fesim describe akmsimple
fesim describe akm, preset(simple)
```

`fesim describe akmsimple` reports the resolved `akm/simple` configuration and scalar-parameter matrix. The same resolver validates named common options and model-specific name-value pairs such as `parameters(mu 3.2 p_ee .10)`, records their sources, and serializes the result deterministically. In the frozen v0.1 contract, all model-specific scalars remain inside `parameters()`; only common controls have named options.

The public simulation route is:

```stata
fesim, dgp(akmsimple) seed(12345) clear
```

This is equivalent to `dgp(akm) preset(simple)`. It generates the required worker-period panel, optional basic truth variables, common moments, metadata, and returned results. Retained periods are streamed into the final worker-major Stata dataset; the implementation does not retain a second full panel in Mata.

## Quick start

Generate a reproducible annual panel and inspect its returned configuration, realized moments, targets, and graph:

```stata
fesim, dgp(akmsimple) workers(5000) firms(250) periods(8) ///
    seed(12345) truth(basic) connectivity(keep) clear

describe
summarize employed lnwage alpha_true psi_true epsilon_true
matrix list r(parameters)
matrix list r(moments)
matrix list r(targets)
matrix list r(network)
```

Use `connectivity(largest)` to retain every period for workers in the selected largest observed component. Under that mode, `r(N_workers)` is the retained worker count; the originally requested count remains in the `workers` row of `r(parameters)`.

Model-specific overrides stay inside `parameters()`:

```stata
fesim, dgp(akmsimple) workers(2000) periods(12) frequency(month) ///
    start(2000m1) seed(9876) ///
    parameters(sd_worker .45 sd_firm .18 p_ee .10) clear
```

[`examples/akmsimple.do`](examples/akmsimple.do) is a tested end-to-end example. It simulates a connected panel and runs an AKM-style regression using only Stata's built-in `areg`; the example adds no runtime dependency.

An internal deterministic toy handler exercises the shared Mata lifecycle and typed containers. It is test infrastructure and is not registered as a public DGP. Only the shared output module may translate its results into the frozen Stata panel scaffold. The common blockwise finalizer constructs observed flow indicators and preserves latent transition counts with explicit boundary-period missingness.

The common result finalizer attaches the frozen dataset characteristics, returns named scalars/macros/matrices, and implements compact `report`/`noreport` behavior without changing data or RNG state.

The internal common moment engine computes risk-set transition rates, employed-observation wage moments, pooled firm-period size and concentration moments, mover/stayer counts, and consistently weighted truth moments. Its exact row and target-comparison contracts are documented in [docs/moments.md](docs/moments.md).

The `akm/simple` module generates persistent worker and firm effects, normalized firm attraction weights, approved initial states, competing employment/mobility transitions, spell and duration state, discrete burn-in, and complete employed wage/truth components on isolated RNG streams. The public route and remaining diagnostic boundary are documented in [docs/akm_simple.md](docs/akm_simple.md).

The simple preset is a transparent stylized design, not an empirical calibration. It reports compressed bipartite worker-firm component diagnostics under `connectivity(keep)` and can retain complete worker histories from the deterministically selected largest component with `connectivity(largest)`. The exact graph and returned-matrix contract is documented in [docs/network.md](docs/network.md). `connectivity(force)` remains unavailable pending an accepted scientific generation rule.

## Installation

Install version 0.1.0 from its immutable release tag:

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/v0.1.0") replace
```

For a local checkout, prepend the repository root to the Stata ado-path:

```stata
adopath ++ "/path/to/fesim"
```

The supported minimum for v0.1 is Stata 19. Exact-source qualification covers Stata/MP 19.0 on macOS Apple Silicon and Windows x86-64; source files may declare the Stata 16 language dialect, but no Stata 16–18 support claim is made without full qualification.

## Concepts

- A **DGP** defines the economic or statistical model.
- A **mobility engine** determines employment transitions and employer links.
- A **preset** supplies a documented parameterization and calibration classification.
- An **observation scheme** converts latent histories into annual, quarterly, or monthly Stata panels.

For example, `dgp(akmsimple)` is an alias for the canonical `dgp(akm) preset(simple)` configuration. The simple preset is stylized, not a paper calibration.

## Development

Read [DESIGN.md](DESIGN.md) before changing public behavior and [PLAN.md](PLAN.md) for the live implementation state. Build and test instructions are in [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/architecture.md](docs/architecture.md).

The qualified component-stream protocol is documented in [docs/rng.md](docs/rng.md), the worker-block output strategy in [docs/output.md](docs/output.md), the common statistical definitions in [docs/moments.md](docs/moments.md), observed graph semantics in [docs/network.md](docs/network.md), frozen tiny-panel scope in [docs/regression.md](docs/regression.md), large-sample test bounds in [docs/statistical_tests.md](docs/statistical_tests.md), and exact-source runtime baselines in [docs/performance.md](docs/performance.md). User-visible release scope is summarized in [CHANGELOG.md](CHANGELOG.md).

`fesim` is released under the MIT License. See [LICENSE](LICENSE).

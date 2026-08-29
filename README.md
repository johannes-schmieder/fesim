# fesim

`fesim` is a Stata/Mata package under active development for simulating linked employer–employee panels. Its intended scope includes transparent AKM-style designs, mobility and network experiments, pay-gap decompositions, and later structural search models, all behind a common output contract.

The installed runtime will use only official Stata and Mata. It will not require a compiled plugin, Python, R, Julia, or a user-written Stata dependency.

## Current implementation status

Version `0.0.0-dev` has shared configuration, registry, component-RNG, time/rate, and block-output foundations. It provides discovery, preset inspection, canonical alias resolution, and deterministic default reporting:

```stata
fesim version
fesim list
fesim presets
fesim presets akm
fesim describe akmsimple
fesim describe akm, preset(simple)
```

`fesim describe akmsimple` reports the resolved `akm/simple` configuration and scalar-parameter matrix. The same resolver validates named common options and model-specific name-value pairs such as `parameters(mu 3.2 p_ee .10)`, records their sources, and serializes the result deterministically. In the frozen v0.1 contract, all model-specific scalars remain inside `parameters()`; only common controls have named options.

Simulation is not implemented in this checkpoint. A simulation invocation is fully resolved and validated without clearing data or consuming random numbers, then exits with a development-stage error. The first end-to-end target remains:

```stata
fesim, dgp(akmsimple) clear seed(12345)
```

Do not use the current source for empirical or Monte Carlo results yet.

## Development installation

After the checkpoint is available on `main`:

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/main") replace
```

For a local checkout, prepend the repository root to the Stata ado-path:

```stata
adopath + "/path/to/fesim"
```

The supported minimum for v0.1 is Stata 19. Current exact-source qualification is on Stata/MP 19.0 for macOS Apple Silicon; source files may declare the Stata 16 language dialect, but no Stata 16–18 support claim is made without full qualification.

## Concepts

- A **DGP** defines the economic or statistical model.
- A **mobility engine** determines employment transitions and employer links.
- A **preset** supplies a documented parameterization and calibration classification.
- An **observation scheme** converts latent histories into annual, quarterly, or monthly Stata panels.

For example, `dgp(akmsimple)` is an alias for the canonical `dgp(akm) preset(simple)` configuration. The simple preset is stylized, not a paper calibration.

## Development

Read [DESIGN.md](DESIGN.md) before changing public behavior and [PLAN.md](PLAN.md) for the live implementation state. Build and test instructions are in [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/architecture.md](docs/architecture.md).

The qualified component-stream protocol is documented in [docs/rng.md](docs/rng.md), and the worker-block output strategy is documented in [docs/output.md](docs/output.md).

The license is intentionally undecided pending owner review; no license grant should be inferred from repository visibility.

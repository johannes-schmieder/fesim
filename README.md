# fesim

`fesim` is a Stata/Mata package under active development for simulating linked employer–employee panels. Its intended scope includes transparent AKM-style designs, mobility and network experiments, pay-gap decompositions, and later structural search models, all behind a common output contract.

The installed runtime will use only official Stata and Mata. It will not require a compiled plugin, Python, R, Julia, or a user-written Stata dependency.

## Current implementation status

Version `0.0.0-dev` is the repository-bootstrap checkpoint. It provides discovery and development-status commands:

```stata
fesim version
fesim list
fesim describe akmsimple
fesim describe akm, preset(simple)
```

Simulation is not implemented in this checkpoint. A simulation invocation is parsed and validated without clearing data or consuming random numbers, then exits with a development-stage error. The first end-to-end target is:

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

The provisional source compatibility level is Stata 16. Checkpoint 1 is tested on Stata/MP 19.0 for macOS Apple Silicon; no broader support claim is made yet.

## Concepts

- A **DGP** defines the economic or statistical model.
- A **mobility engine** determines employment transitions and employer links.
- A **preset** supplies a documented parameterization and calibration classification.
- An **observation scheme** converts latent histories into annual, quarterly, or monthly Stata panels.

For example, `dgp(akmsimple)` is an alias for the canonical `dgp(akm) preset(simple)` configuration. The simple preset is stylized, not a paper calibration.

## Development

Read [DESIGN.md](DESIGN.md) before changing public behavior and [PLAN.md](PLAN.md) for the live implementation state. Build and test instructions are in [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/architecture.md](docs/architecture.md).

The license is intentionally undecided pending owner review; no license grant should be inferred from repository visibility.

# Calibration guide

Select the economic family with `dgp()` and its parameterization with `preset()`.
Use `fesim presets` and `fesim describe` to inspect registered choices before
changing parameters. A paper-inspired label is a bounded target claim.

| Route | Meaning and provenance |
|---|---|
| `akm/simple` | Exogenous interval mobility and additive wages; stylized primitives |
| `akm/stylized` | Monthly duration/type-dependent hazards and destination sorting; uncalibrated |
| `akm/germany_chk_2002_2009` | CHK Table 4 wage-component SDs and Table 5 covariance; mobility remains stylized |
| `akmpaygap/simple` | Stylized two-group wages and mobility with exact decomposition |
| `akmpaygap/cck2016` | Selected CCK group moments and male-reference firm decomposition; distinct surplus normalization |
| `bm/simple` | Exact homogeneous BM equilibrium, stylized structural primitives |
| `cpv/simple` | Finite-firm sequential bargaining with homogeneous workers; stylized primitives |
| `cpv/heterogeneous` | The same CPV protocol with multiplicative mean-one worker ability; stylized primitives |
| `blm/static` | Employed-only finite types, nonlinear Gaussian cell earnings and sorting; illustrative primitives |
| `blm/dynamic` | Monthly persistence, wage-dependent moves and origin-class shifts; illustrative primitives |

## Inspect, modify, and record

```stata
fesim describe akm, preset(germany_chk_2002_2009)
matrix list r(parameters)
fesim, dgp(akm) preset(germany_chk_2002_2009) workers(1000) firms(100) ///
    periods(8) seed(12345) parameters(theta_sort 1.5) clear
matrix list r(parameters)
matrix list r(targets)
display "`r(calibration_class)'"
display "`r(config_sources)'"
```

Named common options control sample size, output timing, initialization, and
burn-in. Model scalars belong in `parameters(name value ...)`; numeric common
controls also retain that legacy input route, without duplicate specification.
The registry is the authoritative default/bounds/unit table. Overrides are
validated before data replacement. Changing a model parameter away from its
preset value reclassifies targeted presets as `targeted_modified` and stylized
presets as `stylized_modified`; layout changes alone do not. Inspect `r(config)`, `r(config_sources)`, `r(parameters)`, and the saved
`fesim_*` dataset characteristics to reproduce the actual configuration.
The printed command and explicit seed should accompany reported results.

## What targets establish

Germany sets worker/firm/error SDs to `.357/.230/.135` and targets covariance
`.0205` (half the paper's reported `.041`). Only `theta_sort=2.2` was fitted:
five calibration seeds and five disjoint validation seeds, 100,000 workers,
10,000 firms, eight years, and five years of monthly burn-in. Calibration and
validation mean covariances `.0206703882` and `.0200683908` meet the declared
`.0015` tolerance. Interactive defaults use a smaller sample. The mean wage,
hazards, duration slopes, and other sorting coefficients remain stylized.
See [the Germany record](akm_germany_chk.md), the tracked
[seed-level fit results](../calibrations/germany_chk_2002_2009_results.csv),
and [reproduction do-file](../calibrations/fit_germany_chk_2002_2009.do).

CCK uses a population standard-normal firm surplus and group-specific premium
schedules. It targets selected wage moments and the male-reference decomposition,
not the paper's full estimation or empirical normalization. Sampling variation
and finite populations prevent exact equality to population targets. Definitions,
source mapping, normalization, and limiting cases are in
[the pay-gap specification](akm_paygap.md) and `calibrations/`.

BM has no empirical calibration claim. `b`, `p`, `lambda_u`, `lambda_e`,
`delta`, and `r` define its wage-posting equilibrium; rates and discounting are
annual and wage/productivity quantities are in levels. `lnwage` is the log of
the accepted wage. Compare finite-economy allocations and hazards to the finite
theory, and continuum profit/quantities to continuum theory. These are distinct
benchmarks; see [the BM derivation](bm_equilibrium.md).

## Adding a calibration

Record the source table, population, years, units, normalization, target mapping,
free versus fixed parameters, objective, seeds, tolerances, and disjoint validation
before fitting. Store auditable numeric results under `calibrations/`, document
claim boundaries, register metadata, and add deterministic and statistical tests.
Do not silently retune a published preset; version its changed defaults and explain
the consequences under the [compatibility policy](compatibility.md).

## CPV presets

`cpv/simple` and `cpv/heterogeneous` are stylized implementations of the original
CPV bargaining protocol. The latter changes only log ability dispersion from
0 to .4 with a population mean-one lognormal normalization. Uniform firm
productivity is 1.5–2, b=1, lambda_u=.5, lambda_e=.3, delta=.2, r=.05, beta=.5.
No empirical skill/sector calibration is claimed. Overrides are classified
`stylized_modified`. Source version and equation audit: [cpv-derivation.md](cpv-derivation.md).

## BLM presets

`blm/static` and `blm/dynamic` implement the employed-only monthly
forward process. They are not Swedish empirical calibrations or BLM estimators.
Static earnings innovations are independent across months conditional on types;
dynamic earnings add persistence, wage-dependent mobility and move shifts.
The default 20-year burn-in is not an exact stationary initialization or a
convergence guarantee. The [BLM note](blm.md) distinguishes the package's
long-panel choices from the audited author short-panel simulators.

All scalar recipes and optional matrix-name inputs belong inside `parameters()`.
For matrix inputs, retain the resolved `r(blm_*)` tables and complete chunked
dataset characteristics: caller matrix names and the short fingerprint do not
uniquely identify the model. These resolved values, not an empirical target
table or an invented additive worker/firm truth decomposition, describe the
simulated economy.

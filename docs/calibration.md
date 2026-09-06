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

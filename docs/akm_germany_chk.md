# CHK-targeted West Germany preset

`dgp(akm) preset(germany_chk_2002_2009)` is a targeted parameterization of the reduced-form monthly mobility engine. It is distinct from the uncalibrated `akm/stylized` preset and has no convenience alias.

## Empirical scope

The empirical source is Card, Heining, and Kline (2013), “Workplace Heterogeneity and the Rise of West German Wage Inequality.” The source sample is full-time West German men ages 20–60 in non-marginal jobs, excluding workers in training. The target interval is 2002–2009, using the largest connected set for the paper's reported AKM estimates.

The runtime targets are:

| Returned moment | Target | Source |
|---|---:|---|
| `alpha_true_sd` | `.357` | CHK Table 4 worker-effect SD |
| `psi_true_sd` | `.230` | CHK Table 4 establishment-effect SD |
| `epsilon_true_sd` | `.135` | CHK Table 4 residual SD |
| `cov_alpha_psi_true` | `.0205` | CHK Table 5 reports `2 cov = .041` |

CHK's reported worker–establishment correlation `.249` is retained as a source cross-check. The package targets the direct covariance because it maps exactly to the existing employment-weighted truth moment. The mean log wage is not targeted; `mu=3` remains a normalization.

## Fitted and stylized parameters

Only `theta_sort` is fitted. The approved fitting design uses 100,000 workers, 10,000 firms, eight annual observations beginning in 2002, five years of monthly burn-in, `network(random)`, and `connectivity(keep)`. Five calibration seeds and five disjoint validation seeds give:

| Seed group | Mean covariance | Difference from `.0205` |
|---|---:|---:|
| Calibration | `.0206703882` | `.0001703882` |
| Validation | `.0200683908` | `-.0004316092` |

Both meet the fixed absolute tolerance `.0015`, yielding `theta_sort=2.2`. Seed-level results are in [`../calibrations/germany_chk_2002_2009_results.csv`](../calibrations/germany_chk_2002_2009_results.csv), with an executable validation harness in [`../calibrations/fit_germany_chk_2002_2009.do`](../calibrations/fit_germany_chk_2002_2009.do).

All transition hazards, duration slopes, `firm_size_sd`, `rho_z_alpha`, `rho_q_psi`, `theta_quality`, `theta_up`, and `theta_down` remain stylized carryovers. They are not German-calibrated. The accurate label is **targeted wage dispersion and sorting**, not a comprehensive Germany mobility calibration.

## Defaults and use

The interactive defaults are 10,000 workers, 1,000 firms, eight annual retained periods beginning in 2002, random initialization, and five years of monthly burn-in. The smaller scale preserves the calibration design's 10:1 worker–firm ratio.

```stata
fesim, dgp(akm) preset(germany_chk_2002_2009) ///
    seed(24680) truth(full) clear

matrix list r(targets)
matrix list r(durations)
```

The preset returns ten target rows, including `cov_alpha_psi_true`, and the same year-valued duration diagnostics as `akm/stylized`. Any model-parameter override changes `r(calibration_class)` from `targeted` to `targeted_modified`.

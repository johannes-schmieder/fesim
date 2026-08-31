# Calibration sources and status

## `akm/simple`

The `akm/simple` values are the owner-approved D-015 teaching and testing baseline. They are stylized package values, not estimates from a paper or administrative dataset.

## `akm/stylized`

The `akm/stylized` values are the owner-approved D-026 stress-design defaults. They are explicitly uncalibrated. Wage and firm-size scales reuse `akm/simple`. The three log-hazard intercepts transform the simple preset's annual probabilities into continuous annual hazards: EU and EE use their shares of the joint `-log(1-.08-.12)` competing rate, and UE uses `-log(1-.60)`. Correlations, covariate slopes, duration slopes, and destination coefficients are modest transparent values selected to exercise the D-025 mechanisms.

No German, paper, or administrative-data label applies to this preset.

## `akm/germany_chk_2002_2009`

This targeted preset uses Card, Heining, and Kline (2013), “Workplace Heterogeneity and the Rise of West German Wage Inequality,” as its empirical source. The source sample is full-time West German men ages 20–60 in non-marginal jobs, excluding workers in training. The targets correspond to the 2002–2009 interval and the largest connected set used for the reported AKM estimates.

CHK Table 4 supplies worker-effect SD `.357`, establishment-effect SD `.230`, and residual SD `.135`. CHK Table 5 reports twice the worker–establishment covariance as `.041`; the runtime covariance target is therefore `.041 / 2 = .0205`. The reported correlation `.249` is retained as a source cross-check, but covariance is the runtime target because it maps directly to `cov_alpha_psi_true`.

Only `theta_sort` is fitted to the sorting target. The fit holds `rho_z_alpha=.30`, `rho_q_psi=.50`, and every other D-026 mobility parameter fixed. It uses 100,000 workers, 10,000 firms, eight annual observations beginning in 2002, five years of burn-in, `network(random)`, `connectivity(keep)`, five fixed calibration seeds, and five disjoint validation seeds. At `theta_sort=2.2`, the calibration mean covariance is `.0206703882` and the held-out validation mean is `.0200683908`; both are within the pre-specified absolute tolerance `.0015` around `.0205`.

The preset is therefore described narrowly as **targeted wage dispersion and sorting**. Its transition hazards, duration dependence, firm-size scale, latent correlations, and remaining destination slopes are transparent D-026 carryovers and are not German-calibrated. `mu=3` is a package normalization rather than a CHK target. The public default panel uses 10,000 workers and 1,000 firms for tractability while preserving the 10:1 worker–firm ratio of the fitting design; it retains the source-aligned eight annual periods beginning in 2002.

Primary source: [accepted manuscript](https://eml.berkeley.edu/~pkline/papers/Germany_resubmit.pdf). The audited runtime targets are in `calibrations/targets.csv`; the seed-level fit and validation record is in `calibrations/germany_chk_2002_2009_results.csv`; the executable validation harness is `calibrations/fit_germany_chk_2002_2009.do`.

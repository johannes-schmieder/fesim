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

## `akmpaygap/simple`

The two-group simple values are the owner-approved D-035 transparent baseline.
They are package values, not estimates from a paper or administrative dataset.
The design uses common transition probabilities and firm attraction so that
worker composition, firm sorting, and premium schedules can be varied
separately.

## `akmpaygap/cck2016`

This targeted preset uses Card, Cardoso, and Kline (2016), “Bargaining,
Sorting, and the Gender Wage Gap: Quantifying the Impact of Firms on the
Relative Pay of Women,” *Quarterly Journal of Economics* 131(2): 633–686.

CCK Table II supplies group-specific log-wage, worker-effect, firm-premium, and
residual standard deviations; mean firm premiums; worker-premium correlations;
and the `.590` cross-group firm-premium correlation. Table III supplies the
men-minus-women total gap `.234`, total firm contribution `.049`,
male-reference sorting `.035`, and male-reference premium-schedule contribution
`.015`. The published rounded sorting and schedule components add to `.050`
while the published firm total is `.049`; `fesim` records all four targets but
uses exact realized adding-up identities.

The package maps those targets to a population-standard-normal common surplus.
In particular, `group_sort_m=.142` is the rounded `.035/.247` sorting tilt;
`premium_loading_f=.12567` is `.590*.213`; and
`premium_deviation_sd_f=.171976891180182` is
`sqrt(.213^2-.12567^2)`. The group/type sorting coefficients and common `.05`
annual trend are supporting reduced-form moment-fit parameters. Equal `.08`,
`.12`, and `.60` group transition probabilities and common `firm_size_sd=1`
are stylized package values, not CCK estimates.

The precise claim is **targeted group wage/effect moments and a male-reference
firm decomposition**. CCK's empirical low-surplus-firm normalization is not
reproduced: `fesim` uses a population-standard-normal latent surplus without
finite-sample restandardization. It also omits the paper's full empirical
estimation, covariates, establishment sample, and counterfactual reweighting.

The audited source PDF SHA-256 is
`0ad3c4a2f0192d2bd78e8901b7ce83e94e080423758282690129c7326ca1978a`.
Primary source: [NBER working paper](https://www.nber.org/papers/w18850) and
[published article](https://doi.org/10.1093/qje/qjv038). Runtime targets are in
`calibrations/targets.csv`, defaults and transformations in
`calibrations/presets.csv`, the fixed validation record in
`calibrations/paygap_cck2016_results.csv`, and the executable large-sample check
in `tests/statistical/paygap_cck_moments.do`.

## fesim_d043: CPV stylized primitives

The two CPV presets implement the original Cahuc–Postel-Vinay–Robin bargaining
protocol with package-chosen primitives. The 20 new CSV rows are not empirical
estimates. Both presets share uniform firm productivity and common rates;
heterogeneous workers change only log ability SD to .4, using mean-one lognormal
ability. Source and finite-equation audit: [cpv-derivation.md](../docs/cpv-derivation.md).

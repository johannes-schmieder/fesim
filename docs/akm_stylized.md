# Stylized empirical-mobility AKM

`akm/stylized` is the first public route using the D-025 monthly empirical-mobility engine:

```stata
fesim, dgp(akm) preset(stylized) seed(12345) clear
```

`dgp(akmempirical)` is an exact alias. The word `empirical` describes the reduced-form mechanisms, not the calibration status. D-026 classifies every default as stylized and uncalibrated; no country, paper, or administrative-data label applies.

## Timing and state

The internal clock is monthly for every output frequency. EU and EE are competing annual continuous-time hazards; UE is a single annual hazard. Tenure and unemployment duration enter through `log(1+duration_years)`. The default random initialization uses employment probability 0.5 and attraction-weighted firms, then discards five years of monthly burn-in. `initial(stationary)` is unavailable because no exact stationary distribution over duration-augmented state has been implemented.

Annual, quarterly, and monthly outputs are end-of-period snapshots. `ntransitions` sums every latent monthly EU, UE, and EE event since the prior output observation, so it can exceed one. `tenure` and the DGP-specific `unemp_duration` are expressed in output-period units. `r(durations)` reports their counts, means, sample standard deviations, and p10/p50/p90 in years, making the diagnostics comparable across output frequencies.

## Population and destinations

Five equiprobable worker mobility types use support `(-2,-1,0,1,2)/sqrt(2)`. `rho_z_alpha` correlates the latent mobility index with the standardized worker wage primitive. Continuous firm quality has mean zero and sample variance one; `rho_q_psi` correlates its latent index with the standardized firm wage primitive. Attraction weights remain a separate firm-size primitive.

UE destinations depend on attraction, worker-type sorting, and firm quality without an origin-firm term. EE destinations additionally exclude the current firm and apply asymmetric upward and downward quality-distance terms. Grouped stabilized tables avoid any worker-by-firm probability matrix.

With `truth(full)`, `worker_type_true` repeats the worker mobility type and `firm_quality_true` records current-firm quality on employed rows. Basic wage truth retains the common additive-AKM variables.

## D-026 defaults

The wage and size parameters reuse the transparent `akm/simple` scale. The three hazard intercepts transform its annual transition probabilities into continuous rates at zero covariates and duration: joint EU/EE rate `-log(1-.08-.12)` split in 0.08/0.12 shares, and UE rate `-log(1-.60)`. The remaining values are modest stress-design coefficients.

| Parameter | Default | Interpretation |
|---|---:|---|
| `mu` | 3 | mean log wage |
| `sd_worker` | .40 | worker-effect SD |
| `sd_firm` | .15 | firm-effect SD |
| `sd_error` | .20 | wage-shock SD |
| `firm_size_sd` | 1 | log attraction scale |
| `wage_trend` | 0 | log points per year |
| `rho_z_alpha` | .30 | worker latent correlation |
| `rho_q_psi` | .50 | firm latent correlation |
| `kappa_eu` | -2.416230718633671 | EU log-hazard intercept |
| `eu_worker`, `eu_firm`, `eu_duration` | .10, -.10, -.20 | EU slopes |
| `kappa_ee` | -2.0107656105255063 | EE log-hazard intercept |
| `ee_worker`, `ee_firm`, `ee_duration` | .10, -.10, -.15 | EE slopes |
| `kappa_ue` | -.08742157179075517 | UE log-hazard intercept |
| `ue_worker`, `ue_duration` | .15, -.25 | UE slopes |
| `theta_sort`, `theta_quality` | .25, .10 | sorting and quality preference |
| `theta_up`, `theta_down` | .20, -.10 | asymmetric EE distance terms |

Every model-specific scalar is accepted only inside `parameters()`. Changing one reclassifies the run as `stylized_modified`. The machine-readable source/status record is [`calibrations/presets.csv`](../calibrations/presets.csv), with explanatory provenance in [`calibrations/sources.md`](../calibrations/sources.md).

## Qualification boundary

The public route is qualified for deterministic alias equivalence, all three output frequencies, monthly transition aggregation, duration-unit conversion, truth modes, caller-state preservation, configuration bounds, and common results. It reuses the already qualified hazard, grouped-destination, lifecycle, graph, moment, and RNG layers.

DG-08 remains open only for a future targeted or Germany-labeled preset. `akm/stylized` must not be cited as a German calibration or as matching empirical targets.

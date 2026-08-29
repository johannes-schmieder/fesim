# Simple-AKM statistical qualification

The statistical tests complement exact fixtures: they ask whether a moderately large public simulation is consistent with the model's declared distributional and independence targets. Seeds are fixed for reproducibility, but tolerances are specified from sampling theory before inspecting the realized pass/fail result.

## Moment and transition test

`tests/statistical/akm_moments.do` simulates 40,000 workers, 400 firms, and 10 annual periods with uniform firm-attraction weights. It uses the following bounds:

- a normal sample mean with target standard deviation `sigma` must be within `8 * sigma / sqrt(n)` of its target;
- a normal sample variance must be within `8 * sigma^2 * sqrt(2 / (n - 1))` of its target;
- each conditional transition proportion must be within eight conditional-binomial standard errors, using its realized eligible risk-set size;
- first-period stationary employment must be within eight Bernoulli standard errors of `p_ue / (p_eu + p_ue)`;
- uniform first-period firm assignment uses a Pearson statistic bounded by the chi-square mean plus eight chi-square standard deviations.

Worker effects use the worker count, firm effects use the active-firm count, and residuals use the employed-observation count. The test requires every firm to be active before applying the 400-firm bounds. Transition risk sets follow the exact origin-state definitions in `docs/moments.md`.

The same run compares errors among the first 2,500 workers with errors in the full 40,000-worker sample for the worker-effect mean, residual mean, and initial stationary employment. These fixed-seed comparisons are a convergence regression, not a theorem that every larger random sample must be closer.

## Exogeneity test

`tests/statistical/akm_exogeneity.do` simulates 30,000 workers, 300 uniformly attractive firms, and eight annual periods. It checks the employment-weighted worker-firm covariance and the first-period covariance against zero, using ten times `sd_worker * sd_firm / sqrt(n)` with an effective worker count.

It then correlates the contemporaneous residual with entry, direct job-to-job movement, new-job, next-period exit, latent transition-count, and tenure measures. Under independent component streams these correlations are zero; each must be below `10 / sqrt(n)` in absolute value using its actual nonmissing sample size.

Eight- and ten-standard-error bands are deliberately conservative family-wide safeguards. They are tight enough to catch material changes in primitive distributions, rate conversion, assignment, sorting, or RNG-stream separation, while making false failures negligible under the declared DGP. Tolerances may change only with an estimand/sample-design explanation, not in response to an isolated failed seed.

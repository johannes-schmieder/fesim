# AKM statistical qualification

The statistical tests complement exact fixtures. The simple-AKM tests ask whether a moderately large public simulation is consistent with declared distributional and independence targets, using sampling-theory tolerances fixed before inspecting pass/fail outcomes. The stylized empirical-mobility test instead uses conservative fixed-seed mechanism contrasts; it is a regression test, not an inferential or calibration test.

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

## Stylized empirical-mobility test

`tests/statistical/akm_stylized_mobility.do` uses 5,000 workers and 100 firms to test three public mechanisms with fixed primitives:

- moving only `theta_sort` from zero to one must raise employment-weighted worker-firm covariance by more than .02, while the zero-sorting covariance remains within .01 of zero;
- latent correlations of .8 must produce positive realized worker-type/worker-effect and firm-quality/firm-effect correlations in broad attenuation-aware ranges;
- changing only the EU/EE/UE duration slopes from zero to materially negative values must increase mean tenure by at least 25 percent and mean unemployment duration by at least 50 percent.

These are conservative mechanism regressions, not empirical target tests. The design deliberately zeros all competing heterogeneity or destination terms relevant to each contrast and holds seed, population size, hazards, and remaining primitives fixed. They complement the exact hazard, destination, lifecycle, and public alias/output tests.

## Pay-gap limiting cases and CCK target validation

`tests/statistical/paygap_limits.do` uses a 20,000-worker all-equal public design
to require a total gap below `.04`, worker composition below `.025`, sorting
below `.015`, an exactly zero common-schedule component, and exact adding-up.
A separate 40,000-worker design assigns distinct group EU/EE/UE probabilities
and requires all six realized rates to lie within fixed conservative bands of
`.006` to `.014`. These bands are wider than eight conditional-binomial
standard errors for the fixed risk sets and seed.

`tests/statistical/paygap_cck_moments.do` uses the documented 100,000-worker,
1,000-firm, eight-year, five-year-burn-in validation design and seed 13579. The
predeclared absolute tolerances are `.025` for group log-wage and premium SDs,
`.01` for worker and residual SDs, `.04` for premium means, `.03` for
worker-premium correlations and the total gap, `.02` for the total firm and
premium-schedule components, and `.01` for male-reference sorting. Every
reference must add within `1e-10`. These are fixed-seed reduced-form calibration
tolerances, not sampling-theory confidence intervals or a claim to reproduce
CCK's empirical estimator.

## Canonical BM theoretical validation

`tests/statistical/bm_moments.do` checks stationary event-driven samples against
the exact finite-firm distribution, with the continuum approximation assessed
separately. Independent workers, rather than repeated worker-period rows, are
the statistical sampling units. Joint unemployment/firm CDF errors use the DKW
uniform bound `sqrt(log(2/1e-10)/(2*N))`. The employed-stock CDF is compared
with the finite stationary worker CDF; offers and accepted unemployment entries
are compared with the finite offer CDF. These distributions are not conflated.

Event counts minus theoretical intensity times exact exposure, unemployed-time
shares, contact CDFs, and strict upward acceptance residuals are aggregated
within workers and checked against eight estimated standard errors of the
independent-worker mean. Three predetermined seeds at 2,000 and 32,000 workers
verify the corresponding fourfold reduction of the sampling-error envelope;
no monotonic realized-error assumption is imposed on random samples. Additional
cases cover random finite firms, equal offer rates, lower unemployed offer
rates, and a one-firm economy. Deterministic 10/100/1,000/10,000-firm grids
verify shrinking offer-CDF, worker-CDF and aggregate EE approximation errors.
Small employed-offer, destruction and discount rates have explicit limiting
checks. `bm_burnin.do` separately compares 20/40-year starts from unemployment
and 20-year random-start convergence. Runtime and source qualification are
recorded in `PLAN.md`; statistical tests do not establish platform portability.

## CPV contracts, tenure and flow validation

`tests/statistical/test_cpv_stationary.do` constructs an independent finite
contract-state generator for a three-firm economy. A dense stationary solve
provides joint employer/reference masses. Uniformization of each within-employer
subgenerator supplies joint contract masses with tenure exceeding two years.
Two disjoint, predetermined 100,000-worker initialization samples must meet
absolute bounds of `.005` for state masses and `.004` for the tenure tail.
These worker-level checks test the dependence between contracts and tenure;
matching employer shares alone would not establish joint stationarity.

A separate 20,000-worker heterogeneous sample over ten years checks the five
finite theoretical versus event-sample flow rows with bounds `.012` for
unemployment and `.015` for the four event hazards. Mean ability must be within
`.02` of one and its correlation with employer productivity within `.035` of
zero. An independent 12,000-worker sample starts unemployed, burns in for
60 years and observes five years; its respective flow bounds are `.02` and
`.025`. These fixed conservative mechanism tolerances are not empirical
calibration confidence intervals. Observation-based transition probabilities
are separately labeled and are not expected to equal continuous-time hazards.

Deterministic tests complement these Monte Carlo checks: dense Bellman and
contract CTMC oracles, tied firms and singletons, beta endpoints, zero employed
offers, numerical range failure/rollback, constant-time wages versus an explicit
offer sum, wage-cut and incumbent-raise fixtures, and the continuum equation-3
integral on 500/5,000-firm grids. Fixed event buffers check right-closed output
boundaries, null contacts and same-firm re-entry. Integration tests compare
block sizes 1/7/333/1201 and nested annual/quarterly/monthly snapshots exactly,
including event counts, exposures, structural state and caller RNG behavior.
See [the CPV derivation](cpv-derivation.md) for the source and model boundary.

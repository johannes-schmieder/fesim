# Two-group AKM pay-gap design

`dgp(akmpaygap)` generates a linked worker-firm panel for men (`group=0`) and
women (`group=1`). Every reported gap is men minus women. The public presets are
the transparent stylized `simple` design and the targeted `cck2016` design.

## Population and wage equation

Each firm has a common surplus index drawn from a population standard normal,

\[
s_j \sim N(0,1).
\]

The realized finite firm sample is not restandardized. Worker effects are
group-specific normal draws, and each group's premium schedule is

\[
\psi_{gj}=a_g+b_gs_j+\tau_g\eta_{gj},
\qquad \eta_{gj}\sim N(0,1).
\]

The deviations are population-mean-zero and independent across groups and of
the common surplus. Employed log wages are

\[
y_{it}=\mu_g+\alpha_i+\psi_{gJ_{it}}+\delta_g t+\epsilon_{it}.
\]

`sd_worker_m`, `sd_worker_f`, `sd_error_m`, and `sd_error_f` control the
group-specific worker and residual distributions. The two `wage_trend_*`
parameters are annual log-wage trends. All model scalars remain inside
`parameters()`.

## Mobility and sorting

Annual EU, EE, and UE probabilities are specified separately by group and
converted to the requested output interval. The internal clock is therefore
the output period. The first public implementation uses one common firm
attraction vector, controlled by `firm_size_sd`.

The standard-normal worker primitive is split at its 20th, 40th, 60th, and
80th percentiles. The five type scores are

\[
(-2,-1,0,1,2)/\sqrt{2}.
\]

For a worker in group `g` and type `k`, origin-free and current-firm-excluding
destination probabilities are proportional to

\[
q_j\exp\{(\gamma_g+\lambda_g z_k)s_j\},
\]

where `q_j` is common attraction, `group_sort_*` is `gamma_g`, and
`worker_sort_*` is `lambda_g`. `network(random)` is the only registered network
design for this DGP. `connectivity(keep)` and `connectivity(largest)` are
available; `connectivity(force)` is not.

## Exact decomposition

Let `M` and `W` denote employed observations for men and women. The firm
component is

\[
F=E_M[\psi_m]-E_W[\psi_w].
\]

The male-reference decomposition is

\[
F=\underbrace{E_M[\psi_m]-E_W[\psi_m]}_{\text{sorting}}
 +\underbrace{E_W[\psi_m-\psi_w]}_{\text{premium schedule}}.
\]

The female-reference decomposition is

\[
F=\underbrace{E_M[\psi_w]-E_W[\psi_w]}_{\text{sorting}}
 +\underbrace{E_M[\psi_m-\psi_w]}_{\text{premium schedule}}.
\]

The symmetric reference averages the two sorting terms and the two schedule
terms. In all three columns,

\[
\text{total gap}=\text{intercept}+\text{worker composition}
+\text{sorting}+\text{premium schedule}+\text{time}+\text{residual}.
\]

`r(decomposition)` reports this nine-row identity and its numerical
`adding_up_error`. The male schedule is the default reference recorded in
`r(reference)`, but all three columns are always returned.

## Returned group results and truth

`r(group_moments)` has columns `men` and `women`. Its 17 rows are worker and
employed-observation counts; employment and wage moments; worker, premium,
residual, and surplus moments; worker-premium correlations; and realized
EU/UE/EE rates. `r(group_targets)` has the same shape.

Basic truth adds `alpha_true`, the observed group-specific `psi_true`, time and
residual components, and exact employed `lnwage_true`. Full truth also adds the
common `firm_surplus_true` and both counterfactual schedules,
`psi_male_true` and `psi_female_true`, at the observed firm. Those three full
truth variables are missing outside employment.

Metadata records `0_men_1_women`, `men_minus_women`, and
`population_standard_normal_no_sample_restandardization` in both `r()` and
dataset characteristics.

## CCK-inspired targeted preset

The empirical source is Card, Cardoso, and Kline (2016), “Bargaining, Sorting,
and the Gender Wage Gap: Quantifying the Impact of Firms on the Relative Pay of
Women.” The runtime targets from Table II are:

| Moment | Men | Women |
|---|---:|---:|
| Log-wage SD | `.554` | `.513` |
| Worker-effect SD | `.420` | `.400` |
| Mean firm premium | `.148` | `.099` |
| Firm-premium SD | `.247` | `.213` |
| Residual SD | `.143` | `.125` |
| Worker-premium correlation | `.167` | `.152` |

Table III supplies a total gap of `.234`, a total firm component of `.049`,
male-reference sorting of `.035`, and a male-reference premium-schedule
component of `.015`. The last two are published rounded components and sum to
`.050`; every simulated decomposition uses the exact realized identity rather
than forcing rounded targets to add.

The standard-normal parameter mapping is transparent. The male loading `.247`
and sorting tilt `.142` map to the `.035` sorting target. The female loading
`.12567=.590*.213` and independent deviation SD
`.171976891180182=sqrt(.213^2-.12567^2)` map the female premium dispersion and
the `.590` cross-schedule correlation. Type-surplus tilts `.18` and `.273`
support the worker-premium correlations. A common annual `.05` trend helps map
the two log-wage dispersions without mechanically changing the group gap.

The fixed validation design uses 100,000 workers, 1,000 firms, eight annual
observations beginning in 2002, five burn-in years, and seed 13579. It produces
total gap `.23940`, firm component `.05287`, male-reference sorting `.03291`,
and male-reference premium-schedule effect `.01997`, while meeting the
predeclared tolerances for every group target. Exact results are in
[`../calibrations/paygap_cck2016_results.csv`](../calibrations/paygap_cck2016_results.csv),
and the executable check is
[`../tests/statistical/paygap_cck_moments.do`](../tests/statistical/paygap_cck_moments.do).

This is a **targeted reduced-form preset**, not a reproduction of CCK's full
empirical model. CCK normalizes firm effects using low-surplus firms. `fesim`
instead uses a population-standard-normal latent surplus, common attraction,
stylized equal transition probabilities, five discrete worker mobility types,
and no covariates or establishment-specific empirical estimates. The returned
levels and counterfactual schedules must be interpreted under the package
normalization.

## Example

```stata
fesim, dgp(akmpaygap) preset(cck2016) seed(24680) ///
    truth(full) noreport clear

matrix list r(group_moments)
matrix list r(group_targets)
matrix list r(decomposition)
matrix list r(decomposition_targets)
```

Any model-parameter override changes the calibration class from `targeted` to
`targeted_modified`.

# fesim

`fesim` is a Stata/Mata package for simulating linked employer–employee panels. Its intended scope includes transparent AKM-style designs, mobility and network experiments, pay-gap decompositions, and structural search models, all behind a common output contract.

The installed runtime uses only official Stata and Mata. It does not require a compiled plugin, Python, R, Julia, or a user-written Stata dependency.

## Current implementation status

The `1.2.0-rc.1` branch adds BLM-style static and dynamic finite-type panels to
the eight existing AKM, pay-gap, BM and CPV presets. BLM supports arbitrary
retained panel lengths, nonlinear earnings interactions, sorting, earnings
persistence and wage-dependent mobility. Its scalar recipes and optional Stata
matrices are documented in [the BLM model note](docs/blm.md).

```stata
fesim, dgp(blm) preset(dynamic) workers(5000) firms(250) ///
    periods(10) seed(12345) truth(full) clear
matrix list r(blm_mean)
matrix list r(blm_cells)
```

BLM is an employed-only monthly forward process with illustrative parameters.
It does not estimate BLM or reproduce the Swedish empirical calibration.
The new source is undergoing qualification; historical CPV evidence belongs to
[the 1.1.0-rc.1 report](docs/qualification-1.1.0-rc.1.md).
The [53-page user and technical manual](docs/fesim_manual.pdf) covers the BLM
syntax, matrix inputs, four new figures and detailed technical appendix. No new tag or release has been created.

## Canonical Burdett–Mortensen

```stata
fesim, dgp(bm) workers(5000) firms(250) periods(10) seed(12345) ///
    truth(full) parameters(b .4 p 1 lambda_u 1 lambda_e .5 delta .2 r .05) clear
matrix list r(solver)
matrix list r(bm_flows)
matrix list r(bm_firms)
```

`bmsimple` is an alias for `bm/simple`. The homogeneous wage-posting model is
exact; its default calibration is stylized. Firms receive permanent midpoint
quantile wages by default; `parameters(random_firms 1)` draws their quantiles.
Offers go uniformly to firms and employed workers accept strictly higher wages.
Stationary starts use exact finite-firm employment masses and backward spell
ages. `burnin()` is measured in continuous years. Annual, quarterly, and monthly
snapshots share the same event history at a fixed seed and horizon.

`r(bm_flows)` distinguishes finite-economy theoretical hazards, exact simulated
event rates, observed transition probabilities, and their descriptive annualized
values. `r(solver)` also reports continuum quantities and discretization errors.
`r(bm_firms)` gives firm-level means/minima/maxima; full truth contains accepted
wages, values, firm quantities, interval event counts, and exposure in years.
`truth(basic)` supplies log wages, posted wages, and productivity. BM uses
`network(random)` and supports `connectivity(keep|largest)`. The 10-million-event
budget for each burn-in/retained stage fails transactionally if exceeded.
See [the derivation](docs/bm_equilibrium.md) and [example](examples/bmsimple.do).

## Quick start

Generate a reproducible annual panel and inspect its returned configuration, realized moments, targets, and graph:

```stata
fesim, dgp(akmsimple) workers(5000) firms(250) periods(8) ///
    seed(12345) truth(basic) connectivity(keep) clear

describe
summarize employed lnwage alpha_true psi_true epsilon_true
matrix list r(parameters)
matrix list r(moments)
matrix list r(targets)
matrix list r(network)
matrix list r(leaveout)
```

Use `connectivity(largest)` to retain every period for workers in the selected largest observed component. Under that mode, `r(N_workers)` is the retained worker count; the originally requested count remains in the `workers` row of `r(parameters)`. The 21-row `r(network)` combines bipartite component summaries with undirected observed firm-mobility link counts, direction-pooled move-count weights, active firms with no movers, articulation-firm counts, and graph-bridge-link counts; all returned-column summaries are recomputed after filtering. The separate 19-row `r(leaveout)` reports the KSS-aligned leave-one-worker set and complete-match vulnerabilities on the returned panel's largest bipartite component. It is an audit only and does not filter the public panel.

Model-specific overrides stay inside `parameters()`:

```stata
fesim, dgp(akmsimple) workers(2000) periods(12) frequency(month) ///
    start(2000m1) seed(9876) ///
    parameters(sd_worker .45 sd_firm .18 p_ee .10) clear
```

Generate a four-community mobility stress design with the default ninefold
same-block destination weight:

```stata
fesim, dgp(akmsimple) network(blocks) workers(2000) firms(100) ///
    periods(8) seed(24680) truth(full) ///
    parameters(block_count 4 block_log_bonus 2.1972245773362196) clear

tabulate worker_block_true firm_block_true if employed
```

Worker home communities govern origin-free initialization and job finding;
the current firm's community governs direct employer moves. Full truth adds
`worker_block_true` and the current `firm_block_true`. These are simulation
design labels, not claims of leave-out or KSS connectedness. See
[docs/network.md](docs/network.md).

Generate the minimum adjacent-block bridge chain and inspect its exact ledger:

```stata
fesim, dgp(akmsimple) network(bridges) workers(2000) firms(100) ///
    periods(8) seed(86420) truth(full) ///
    parameters(block_count 4) clear

summarize nbridges_imposed
matrix list r(bridges)
```

`bridge_count` defaults to `block_count-1`. Bridge workers are distinct and
chosen by an isolated random priority among workers with eligible retained EE
events. Extra bridges cycle over pairs 1-2, 2-3, ..., and the command fails
rather than fabricate events or return an incomplete plan. The ledger records
worker, output/internal period, source/target firm, and source/target block.
This is an imposed block-level stress design, not a KSS or leave-out
connectedness claim.

Generate a reduced-form firm-wage ladder while preserving event timing,
initialization, and job-finding destinations:

```stata
fesim, dgp(akmsimple) network(ladder) workers(2000) firms(100) ///
    periods(8) seed(97531) truth(full) ///
    parameters(ladder_down_share .1 ladder_lateral_share .2 ///
        ladder_up_share .7 ladder_band .1) clear
```

The lateral band is measured in percentile-rank distance using tied midranks.
Unavailable directions are removed and the configured shares are renormalized;
ordinary DGP weights are retained within direction. The design reuses the
event's existing destination uniform and is explicitly reduced-form, not a
structural Burdett–Mortensen or revealed-preference model.

[`examples/akmsimple.do`](examples/akmsimple.do) is a tested end-to-end example. It simulates a connected panel and runs an AKM-style regression using only Stata's built-in `areg`; the example adds no runtime dependency.

The monthly empirical-mobility route can be sampled annually, quarterly, or monthly:

```stata
fesim, dgp(akmempirical) workers(5000) firms(250) periods(8) ///
    seed(24680) truth(full) clear

summarize tenure unemp_duration
matrix list r(durations)
```

Its `akm/stylized` defaults are deliberately uncalibrated. Wage and firm-size scales reuse the simple baseline, continuous-hazard intercepts anchor its zero-covariate transition intensities to the simple annual probabilities, and modest slopes exercise worker heterogeneity, firm quality, duration dependence, sorting, and asymmetric moves. `ntransitions` aggregates all monthly events between output snapshots; `r(durations)` reports tenure and unemployment-duration distributions in years. With `truth(full)`, `worker_type_true` and `firm_quality_true` expose the core latent mobility objects. All coefficients remain inside `parameters()`. See [docs/akm_stylized.md](docs/akm_stylized.md), [`examples/akm_stylized.do`](examples/akm_stylized.do), and the auditable status table in [`calibrations/presets.csv`](calibrations/presets.csv).

The separate `akm/germany_chk_2002_2009` preset targets Card, Heining, and Kline's 2002–2009 West German AKM worker-effect SD `.357`, establishment-effect SD `.230`, residual SD `.135`, and worker–establishment covariance `.0205`. Only `theta_sort=2.2` is fitted, using five 100,000-worker calibration seeds and five disjoint validation seeds. Transition hazards and durations remain D-026 stylized values, so the precise claim is **targeted wage dispersion and sorting**. See [docs/akm_germany_chk.md](docs/akm_germany_chk.md), [`examples/akm_germany_chk.do`](examples/akm_germany_chk.do), and the audited files under [`calibrations/`](calibrations/).

Generate a two-group panel and inspect the exact men-minus-women
decomposition under male, female, and symmetric premium-schedule references:

```stata
fesim, dgp(akmpaygap) preset(cck2016) workers(5000) firms(500) ///
    periods(8) burnin(5) seed(13579) truth(full) noreport clear

matrix list r(group_moments)
matrix list r(group_targets)
matrix list r(decomposition)
matrix list r(decomposition_targets)
```

`group=0` denotes men and `group=1` women; all gaps are men minus women. The
common firm-surplus index is population standard normal without realized-sample
restandardization. `r(decomposition)` adds exactly and always includes
male-reference, female-reference, and symmetric columns. The CCK-inspired
preset targets selected Table II group moments and Table III total/firm/sorting
moments, but it does not reproduce CCK's empirical low-surplus-firm
normalization or full estimation procedure. See
[docs/akm_paygap.md](docs/akm_paygap.md),
[`examples/akmpaygap_cck2016.do`](examples/akmpaygap_cck2016.do), and the
audited records under [`calibrations/`](calibrations/).

An internal deterministic toy handler exercises the shared Mata lifecycle and typed containers. It is test infrastructure and is not registered as a public DGP. Only the shared output module may translate its results into the frozen Stata panel scaffold. The common blockwise finalizer constructs observed flow indicators and preserves latent transition counts with explicit boundary-period missingness.

The common result finalizer attaches the frozen dataset characteristics, returns named scalars/macros/matrices, and implements compact `report`/`noreport` behavior without changing data or RNG state.

The internal common moment engine computes risk-set transition rates, employed-observation wage moments, pooled firm-period size and concentration moments, mover/stayer counts, and consistently weighted truth moments. Its exact row and target-comparison contracts are documented in [docs/moments.md](docs/moments.md).

The `akm/simple` module generates persistent worker and firm effects, normalized firm attraction weights, approved initial states, competing employment/mobility transitions, spell and duration state, discrete burn-in, and complete employed wage/truth components on isolated RNG streams. The public route and remaining diagnostic boundary are documented in [docs/akm_simple.md](docs/akm_simple.md).

The simple preset is a transparent stylized design, not an empirical calibration. It reports compressed bipartite worker-firm component diagnostics under `connectivity(keep)` and can retain complete worker histories from the deterministically selected largest component with `connectivity(largest)`. The exact graph and returned-matrix contract is documented in [docs/network.md](docs/network.md). `connectivity(force)` remains unavailable pending an accepted scientific generation rule.

## Installation

Install version 0.1.0 from its immutable release tag:

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/v0.1.0") replace
```

For a local checkout, prepend the repository root to the Stata ado-path:

```stata
adopath ++ "/path/to/fesim"
```

The supported minimum for v0.1 is Stata 19. Exact-source qualification covers Stata/MP 19.0 on macOS Apple Silicon and Windows x86-64; source files may declare the Stata 16 language dialect, but no Stata 16–18 support claim is made without full qualification.

## Concepts

- A **DGP** defines the economic or statistical model.
- A **mobility engine** determines employment transitions and employer links.
- A **preset** supplies a documented parameterization and calibration classification.
- An **observation scheme** converts latent histories into annual, quarterly, or monthly Stata panels.

For example, `dgp(akmsimple)` and `dgp(akmempirical)` are aliases for the canonical `dgp(akm) preset(simple)` and `dgp(akm) preset(stylized)` configurations. Both presets are stylized, not paper or country calibrations. `akmpaygap/cck2016` is separately classified as targeted.

## Development

Read [DESIGN.md](DESIGN.md) before changing public behavior and [PLAN.md](PLAN.md) for the live implementation state. Build and test instructions are in [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/architecture.md](docs/architecture.md).

The qualified component-stream protocol is documented in [docs/rng.md](docs/rng.md), the worker-block output strategy in [docs/output.md](docs/output.md), the common statistical definitions in [docs/moments.md](docs/moments.md), the pay-gap model in [docs/akm_paygap.md](docs/akm_paygap.md), the canonical BM equilibrium in [docs/bm_equilibrium.md](docs/bm_equilibrium.md), observed graph semantics in [docs/network.md](docs/network.md), frozen tiny-panel scope in [docs/regression.md](docs/regression.md), large-sample test bounds in [docs/statistical_tests.md](docs/statistical_tests.md), and exact-source runtime baselines in [docs/performance.md](docs/performance.md). User-visible release scope is summarized in [CHANGELOG.md](CHANGELOG.md).

`fesim` is released under the MIT License. See [LICENSE](LICENSE).

## Candidate review and compatibility

See the [P6 audit](docs/p6_audit.md), [calibration guide](docs/calibration.md),
[compatibility policy](docs/compatibility.md), and
[qualification/publishing guide](docs/publishing.md). This candidate preserves
simulation defaults and seeded paths. Public API level 1 and Mata API 33 remain
unchanged. No new tag or release is implied. Cite the software using
[CITATION.cff](CITATION.cff), record the exact version/SHA, and cite the relevant
DGP paper separately; a software citation does not establish empirical calibration.

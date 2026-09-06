# Changelog

## Unreleased — 1.1.0-rc.1 CPV candidate

- Add `cpv/simple` and `cpv/heterogeneous`: finite-firm Bellman solution,
  sequential bargaining, incumbent raises, wage-cutting moves and multiplicative
  worker ability. Exact joint stationary contracts/tenure, continuous events,
  burn-in and bounded worker blocks preserve truth/frequency/block invariants.
- Add structural CPV truth, finite firm summaries, and distinct theoretical,
  event-sample and observed flows. Reject nonviable firms, nonpositive entry
  wages and nonfinite lifetime values transactionally under every truth mode.
- Add five independent solver/event/public/invariance/statistical test files;
  source/archive suites now cover 68 files, eight installed presets and the
  72-case common truth/frequency grid.
- Expand help to 17 one-click examples and the manual to 42 pages, ten figures
  and a detailed CPV appendix. Include stylized source records and AKM/mover
  examples with explicit descriptive interpretation.
- Public API remains 1; Mata API advances to 36. Legacy engine algorithms and
  matched deterministic controls are preserved. All 20 CPV scale cases pass;
  two initial legacy performance outliers are resolved by three matched repeats.
- Exact candidate and evidence: [qualification report](docs/qualification-1.1.0-rc.1.md).
  macOS MP 19 qualification only; no new tag or release.

## Earlier unreleased — 1.0.0-rc.1 candidate

- Complete six-preset discovery with variable inventories, units/bound closure,
  initialization/network support, and scientific source/target scope.
- Add cross-DGP frequency/truth/state/override tests and register all six manual
  examples in the full suite; isolated installation now includes CCK.
- Reject stale or incomplete qualification receipts; add exact-archive validation
  and matched 26-case performance controls.
- Reconcile architecture and design status; add calibration, compatibility, and
  publishing guides. Synchronize candidate version and illustrated manual.
- Economic defaults, simulation algorithms, public API level 1, and Mata API 33
  are unchanged. Candidate qualification is macOS MP 19 only; tags/publication
  and broader platform qualification remain separate owner gates.

## 0.4.0 development milestones

- Public canonical `bm/simple` and `bmsimple`: analytical equilibrium, finite
  firms, exact continuous-time events, stationary/random/all-unemployed starts,
  continuous burn-in, annual/quarterly/monthly panels, structural truth, and
  separate theoretical/event/observed moments.
- Buffered worker blocks preserve monolithic seeded histories while bounding
  retained event/panel memory. Removed per-offer firm scans and quadratic
  stationary exit-rate work. Added transaction-safe public failures, compact
  firm diagnostics, connectivity-conditioned sample rates, examples, and tests.
- Theoretical validation includes worker-clustered sampling bounds, acceptance
  compensators, finite-grid convergence, burn-in stability, and limiting cases.
  Tiny-destruction CDF endpoints and singleton-firm output indexing are robust.
- Exact source/platform and performance evidence are recorded in `PLAN.md` and
  `docs/performance.md`. No new release tag is implied by development status.

## Earlier 0.3.0 development checkpoints

### Scientific contract and internal solver; public runtime pending

- Fixed D-036 for the planned `bm/simple` route: homogeneous workers and
  common-productivity firms, permanent wage posting, distinct unemployed and
  employed offer rates, endogenous reservation wages, and steady-state
  flow-profit maximization. The exact analytical equilibrium, output-unit
  mapping, limits, and executable hand check are documented. An API-28
  internal analytical solver now adds cancellation-safe evaluation, an
  independent quadrature residual, support-grid and equal-profit validation,
  and explicit failure diagnostics. D-037 adds deterministic midpoint-quantile
  finite firms by default plus an isolated-stream random mode, stable
  wage-ranked IDs, exact discrete stationary employment under strict upward
  acceptance, and separate approximation diagnostics. D-038/API 29 adds an
  internal exact continuous-time event engine with competing employed offers
  and destruction, unemployed offers, uniform firm contacts, recorded rejected
  offers, strict tie handling, stable spells and continuous durations, and
  event/destination stream isolation. D-039/API 30 adds exact finite stationary
  initialization with stationary backward spell ages, documented random and
  draw-free all-unemployed starts, unrecorded burn-in, retained-boundary count
  reset, convergence diagnostics, and initialization-stream isolation. D-040
  and API 31 add right-closed end-of-period aggregation at annual, quarterly,
  and monthly frequencies, exact interval exposure and primitive/accepted
  event counts, adjacent-endpoint observed flows, and explicitly separated
  theoretical, event, and observed flow diagnostics. D-041 and API 32 add a
  private public-shaped panel writer, level-to-log accepted-wage mapping,
  none/basic/full BM truth, closed-form worker values, exact interval truth,
  and separately labeled finite-versus-continuum firm diagnostics. The public
  simulation route is not yet implemented.

### Implemented on `main`

- Public `dgp(akmpaygap)` with stylized `simple` and targeted `cck2016`
  presets; men are `group=0`, women are `group=1`, and all gaps are men minus
  women.
- Population-standard-normal common firm surplus without realized-sample
  restandardization; group-specific worker effects, premium schedules,
  residual dispersions, annual transition probabilities, destination sorting,
  and wage trends.
- Exact male-reference, female-reference, and symmetric decompositions into
  intercept, worker composition, sorting, premium schedule, time, and residual
  components, with explicit adding-up errors and normalization metadata.
- Two-column group moment/target matrices, full counterfactual premium-schedule
  truth, CCK Table II/III target records and transformations, a fixed
  100,000-worker validation record, limiting-case tests, and a documented
  end-to-end example.
- Promoted the development version from `0.2.0-dev` to `0.3.0-dev` to match
  the DESIGN release ladder after opening the P4 public family.

- Standardized the installed help header, sources, and contact footer and
  added three self-contained one-click documentation workflows.
- Public `dgp(akm) preset(stylized)` simulation and the exact
  `dgp(akmempirical)` alias under the owner-approved D-025/D-026 contracts.
- Monthly internal EU/EE/UE hazards with worker, firm, tenure, and unemployment
  duration heterogeneity; grouped origin-free UE and current-excluding
  asymmetric EE destinations; and five correlated worker mobility types plus
  continuous correlated firm quality.
- Monthly-to-output latent-transition aggregation, output-period tenure and
  unemployment duration, year-valued `r(durations)` distributions, and full
  worker-type/firm-quality truth.
- Auditable stylized parameter records and a registry-consistency test. The
  generic `akm/stylized` defaults remain explicitly uncalibrated.
- Distinct `akm/germany_chk_2002_2009` targeted preset using CHK worker,
  establishment, and residual dispersions plus worker--establishment covariance;
  only `theta_sort` is fitted on five calibration seeds and validated on five
  disjoint seeds. Hazards and durations remain labeled stylized carryovers.
- Expanded `r(network)` with an undirected observed firm mobility graph:
  distinct firm links, direction-pooled observed move-count weights, active
  firms with no movers, p10/p50/p90/p99 link-weight summaries, articulation
  firms, and graph-bridge links. Returned diagnostics are recomputed after
  largest-component filtering; no leave-out-connectedness claim is made.
- Added a separate 19-row `r(leaveout)` audit on the observed unique-match
  bipartite graph. It reports the KSS-aligned set obtained by deleting complete
  histories of articulation workers and repeatedly retaining the largest
  component until it is robust or empty, plus complete-match vulnerabilities
  on both the base and worker-robust graphs. The iteration is a conservative
  extension of KSS Algorithm 1 for cases where pruning creates new cut workers.
  Stayer leaf edges are not misclassified as firm-disconnecting matches, and
  the audit does not filter the returned panel or label a separate match sample.
- Shared `network(random)` destination primitives for attraction-weighted
  common assignments and current-firm-excluding direct moves. All public AKM
  presets preserve the relevant route's frozen draws and output.
- Common `network(blocks)` stress designs with balanced independent worker and
  firm communities on isolated RNG stream 109, same-block destination weights,
  exact zero-bonus nesting of the random rule, block truth variables, and
  explicit metadata. These labels do not claim leave-out connectedness.
- Exact `network(bridges)` stress designs with strict ordinary communities,
  globally priority-selected distinct workers, deterministic adjacent-block
  plans, destination-only overrides of existing retained EE events, per-output
  intervention counts, exact `r(bridges)` ledgers, and failure rather than
  fabricated or incomplete links. The completed block chain is not a KSS or
  leave-out connectedness claim.
- Reduced-form `network(ladder)` EE destinations based on persistent
  firm-wage-effect midranks, with configurable downward/lateral/upward shares,
  an inclusive lateral percentile band, boundary renormalization, ordinary
  within-direction DGP weights, and no change to initialization, UE, event
  draws, or RNG consumption. This is not a structural BM claim.

## 0.1.0 — 2026-08-29

### Implemented

- Public `dgp(akm) preset(simple)` simulation and the `dgp(akmsimple)` alias.
- Reproducible worker-period panels at annual, quarterly, and monthly output
  frequencies with isolated component RNG streams.
- Stylized worker and firm effects, exogenous mobility, unemployment, wages,
  burn-in, and basic/full/none truth-output modes.
- Common flow, wage, firm-size, concentration, mover/stayer, truth-component,
  and target-comparison results.
- Compressed observed worker-firm graph diagnostics and deterministic
  `connectivity(largest)` filtering that retains complete worker histories.
- Dataset metadata, public returned matrices, stage runtimes, tested examples,
  source-only package installation, and exact-source qualification tooling.
- Frozen deterministic fixtures, large-sample statistical tests, and public
  performance baselines through 1,000,000 workers and 10,000,000 rows.

The `akm/simple` defaults are a transparent stylized teaching and testing
design. They are not an empirical or paper calibration.

### Planned, not implemented in 0.1.0

- The later `akm/stylized` route and `akmempirical` alias.
- `akmpaygap/simple` and the CCK-inspired `akmpaygap/cck2016` preset.
- `bm/simple` and the `bmsimple` alias; D-036 is accepted, but the solver and
  simulation route remain pending.
- `connectivity(force)`, pending an accepted scientific generation rule.
- Cross-platform or cross-version bitwise reproducibility beyond the exact
  environments recorded in `PLAN.md`.

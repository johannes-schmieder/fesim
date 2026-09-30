# Public interface contract

The installed help, model notes, and this contract describe the current
interface. The registry in `fesim_registry.ado` and `fesim__blm_registry.ado`
is authoritative for preset values, bounds, units, and applicability.

## Source inventory

| Field | Value |
| --- | --- |
| Package version | `1.2.0-rc.1` |
| Public API | `1` |
| Mata API | `37` |
| Registered presets | `akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016 bm/simple cpv/simple cpv/heterogeneous blm/static blm/dynamic` |
| Registered Stata files | `73` |

Static CI checks this table against runtime source and the test runner. This is
an inventory, not a claim about the execution of a particular test run.

## Commands and inputs

`fesim version`, `fesim list`, `fesim presets [dgp]`, and
`fesim describe dgp, preset(name)` are nonmutating discovery commands.
Simulation defaults to `akm/simple`. Aliases `akmsimple`, `akmempirical`, and
`bmsimple` resolve to `akm/simple`, `akm/stylized`, and `bm/simple`.

Named common options are `dgp()`, `preset()`, `workers()`, `firms()`,
`periods()`, `frequency()`, `start()`, `seed()`, `initial()`, `burnin()`,
`jobrule()`, `truth()`, `connectivity()`, `network()`, `report`, `noreport`,
and `clear`. Model controls remain name/value pairs in `parameters()`;
BLM matrix values are existing Stata matrix names. Numeric common controls
also accept the legacy `parameters()` route, but duplicates are rejected.

Preflight rejects unknown, duplicate, inapplicable, nonfinite, out-of-bounds,
and inconsistent inputs before replacing data or consuming simulation draws.
BLM matrices are copied and validated without changing caller matrices.
Only `jobrule(end)` is supported. `connectivity(force)` is reserved and rejected.

## Time, sample, and output

`periods()` counts output snapshots. `frequency(year|quarter|month)` selects
their units and Stata time format. Model probabilities, hazards, persistence,
and burn-in keep their documented units; see the model-specific notes.

The returned data are sorted by `workerid time` with a unique worker/date key.
Common fields are `workerid time firmid employed lnwage spellid tenure newjob
from_unemp to_unemp jobtojob ntransitions`. Nonemployment rows retain the worker
and time but have missing employer and wage. BLM is employed-only.

Observed flow flags compare adjacent output snapshots with documented boundary
missingness. Latent transition counts can exceed the observed moves.
BM/CPV exact event rates and exposure, theoretical hazards, and observed
endpoint probabilities are distinct objects. Do not relabel one as another.

`truth(none|basic|full)` controls latent columns without changing common economic
draws. Truth is model-specific: additive AKM effects, structural BM/CPV objects,
and BLM type/cell earnings are distinct. BLM supplies no additive AKM truth.
See [output](output.md), [results](results.md), and [moments](moments.md).

`connectivity(keep)` is the default. `largest` retains complete histories for
workers in the deterministic largest observed bipartite component. Requested
workers remain in `r(parameters)`; `r(N_workers)` counts retained workers.
Graphs and moments are recomputed for that returned population. `r(leaveout)`
is an audit only and does not filter a leave-out sample.

The four AKM network designs are `random`, `blocks`, `bridges`, and `ladder`.
Other families accept `random` only. Imposed bridges and ordinary firm-graph
bridges are distinct, and neither design labels nor graph summaries guarantee
KSS leave-out connectedness or BLM mixture identification. See [network](network.md).

## Reproducibility and safety

Without `clear`, a nonempty caller dataset is protected. Successful simulation
with `clear` replaces it; a failed simulation restores data and RNG state.
Discovery never advances the RNG. With `seed()`, the caller RNG is unchanged;
without it, one integer draw supplies the recorded master seed.

Component streams isolate population, initialization, mobility, destinations,
wages, and network design. Truth and output blocking preserve seeded paths.
Frequency nesting applies to the shared monthly and continuous-history routes
under a matched horizon; it does not imply that changing an interval-clock
model's frequency preserves its latent path. Bitwise reproducibility is qualified
for a fixed source, command, seed, and Stata environment. See [RNG](rng.md).

Every filename installed by `fesim.pkg` starts with `fesim`, including private
`fesim__*` helpers, Mata and help. Static CI enforces this SSC packaging rule.

The installed runtime uses only official Stata/Mata. No plugin, foreign runtime,
or user-written Stata dependency is allowed. Output is written in worker blocks;
temporary memory is bounded, but the returned dataset still scales with the
requested population. Source-only installation must work without a development
Mata library. Caller timers, temporary objects, and failure cleanup are owned
transactionally; see [architecture](architecture.md).

## Scientific and compatibility boundaries

Presets are stylized unless explicitly classified as targeted. Germany targets
selected CHK wage dispersion/covariance, with stylized mobility. CCK targets
selected group moments and decomposition under the package's own normalization.
Neither is a full empirical replication. BM is homogeneous-worker and
common-productivity. CPV has finite heterogeneous firms and optional multiplicative
worker ability. BLM is a finite-type forward process with illustrative primitives,
not an estimator or a general equivalent of conditional author simulators.
See [calibration](calibration.md) and the relevant derivations.

Within public API 1, defaults, existing option meanings, output semantics,
matrix names/order, sample rules, and normalization are compatibility commitments.
Breaking changes require a major version and migration notes; numerical fixes
must disclose whether seeded paths change. Platform claims require exact-source
qualification. See [compatibility](compatibility.md) and [validation](validation.md).

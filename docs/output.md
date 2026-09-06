# Block-output implementation

The common output layer implements the early deterministic spike and all public AKM streaming presets.

## Strategy

- Calculate and validate `workers × periods` before allocating observations.
- Cap the provisional common path at the lower of Stata's theoretical observation limit and 2,147,483,647 observations.
- Create final Stata variables once with explicit storage types.
- Assemble deterministic worker-major blocks and write each column with vectorized `st_store()` calls.
- Target at most 250,000 output rows per adaptive block, while never splitting a worker's requested periods across blocks.
- Retain only worker-length dynamic state and the current output block in Mata; do not retain a full second panel copy.
- Finalize sorting, labels, characteristics, and any cross-block metadata only after all blocks are written.

The toy writer uses `long` IDs and time, `byte` employment status, and `double` wages. The public simple-AKM route extends this scaffold with the complete frozen variable and storage-type contract verified by `tests/integration/test_panel_contract.do`. The stylized empirical-mobility route adds `unemp_duration` and, under full truth, `worker_type_true` and `firm_quality_true`.

The private lifecycle integration creates the complete frozen panel through the shared output module and remains small, materialized test infrastructure. The public simple-AKM handler instead allocates the final Stata dataset once, stores each retained period into its worker-major row positions, and finalizes adjacent-observation flows in adaptive complete-worker blocks. It applies explicit storage types, labels, `%ty`, `%tq`, or `%tm` formatting, sorting, and `isid workerid time` validation without retaining a full duplicate panel.

Public error handling is coordinated by the ado boundary. Configuration and unsupported-mode errors precede any replacement or draw. If a scientific or output error occurs after an authorized `clear`, the prior dataset and caller RNG state are restored. A source-only clean-install test removes the development Mata library before simulation, proving that the packaged Mata sources and internal loader are sufficient at runtime.

The empirical handler advances a fixed monthly state twelve, three, or one times per annual, quarterly, or monthly output interval. It sums each monthly transition vector before writing `ntransitions`, converts internal year-valued tenure and unemployment duration to output-period units, and keeps only worker-length state plus current wage components. `_fesim_durations` converts the retained panel back to years for comparable distribution returns without changing data or RNG state.

`src/fesim_flows.mata` finalizes one or more complete worker histories at a time. `newjob`, `from_unemp`, `jobtojob`, and `ntransitions` are missing in each worker's first output period because no prior observation exists. `to_unemp` is defined from the current and next observed states and is missing in the last period. A changed spell marks `newjob=1` even when the observed firm ID is unchanged, while `jobtojob=1` requires employment at different observed firms in adjacent periods. This distinguishes a same-firm return after nonemployment or hidden within-period moves from a directly observed employer-to-employer transition.

## Validation and memory accounting

The integration test writes the same deterministic panel with one-worker, nine-worker, and all-worker blocks and compares every value, row order, missing-value rule, and storage type. It also verifies `isid workerid time`, unchanged RNG state, and observation-count failures.

`network(bridges)` extends the streaming panel with byte
`nbridges_imposed`, written for every truth mode. It is zero in the first
retained period and records the number of design-imposed EE destinations for
that worker during each later output interval. Distinct bridge workers make the
current contract binary per worker over the full simulation, while the count
name leaves the interval semantics explicit. Finalization verifies that its
generated-panel sum equals the exact bridge plan before graph filtering.

The early spike exposes conservative final-panel and peak-working-byte estimates for the shared writer. Public simple-AKM benchmarks additionally record exact-source command/stage time, dataset width, maximum resident set size, and peak process footprint; see [`docs/performance.md`](performance.md). Later DGP modules must extend the accounting for their own live state rather than silently relying on either the toy estimate or simple-AKM measurements.

## CPV output

The CPV writer stores 13 common observed variables, five basic structural truth
variables and 17 further full-truth variables. Worker ability is always defined
when truth is requested; employer/contract fields are missing during unemployment.
Reference firm 0 denotes unemployment. Incumbent raises do not change spell IDs,
tenure or transition counts. Exact offers, rejections, raises, transitions and
exposure include the first interval, although its public transition count is
missing. See [the manual](fesim_manual.pdf) and [derivation](cpv-derivation.md).


## BLM output

The finite-type writer returns 13 common variables, six basic truth columns and
eight full-truth additions. Every row is employed; unemployment duration is
always missing. Monthly earnings, event and destination draws are buffered in
worker-major order, with 100,000 target output rows per block and at most 10,000
workers. Annual/quarterly/monthly output takes endpoint snapshots after 12/3/1
updates. Tenure resets to zero on every actual-firm move, including within-class
moves. Full truth's lags and conditional quantities refer to the last internal
month; interval move counts include the first retained interval. Common adjacent
flow missing-value rules are unchanged. Full matrix provenance is chunked without
truncation. See [the model note](blm.md) and [manual](fesim_manual.pdf).

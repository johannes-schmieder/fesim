# Block-output implementation

The common output layer implements both the early deterministic spike and the public simple-AKM streaming route.

## Strategy

- Calculate and validate `workers × periods` before allocating observations.
- Cap the provisional common path at the lower of Stata's theoretical observation limit and 2,147,483,647 observations.
- Create final Stata variables once with explicit storage types.
- Assemble deterministic worker-major blocks and write each column with vectorized `st_store()` calls.
- Target at most 250,000 output rows per adaptive block, while never splitting a worker's requested periods across blocks.
- Retain only worker-length dynamic state and the current output block in Mata; do not retain a full second panel copy.
- Finalize sorting, labels, characteristics, and any cross-block metadata only after all blocks are written.

The toy writer uses `long` IDs and time, `byte` employment status, and `double` wages. Those types validate the mechanism but do not yet freeze every final output type.

The private lifecycle integration creates the complete frozen panel through the shared output module and remains small, materialized test infrastructure. The public simple-AKM handler instead allocates the final Stata dataset once, stores each retained period into its worker-major row positions, and finalizes adjacent-observation flows in adaptive complete-worker blocks. It applies explicit storage types, labels, `%ty`, `%tq`, or `%tm` formatting, sorting, and `isid workerid time` validation without retaining a full duplicate panel.

Public error handling is coordinated by the ado boundary. Configuration and unsupported-mode errors precede any replacement or draw. If a scientific or output error occurs after an authorized `clear`, the prior dataset and caller RNG state are restored. A source-only clean-install test removes the development Mata library before simulation, proving that the packaged Mata sources and internal loader are sufficient at runtime.

`src/fesim_flows.mata` finalizes one or more complete worker histories at a time. `newjob`, `from_unemp`, `jobtojob`, and `ntransitions` are missing in each worker's first output period because no prior observation exists. `to_unemp` is defined from the current and next observed states and is missing in the last period. A changed spell marks `newjob=1` even when the observed firm ID is unchanged, while `jobtojob=1` requires employment at different observed firms in adjacent periods. This distinguishes a same-firm return after nonemployment or hidden within-period moves from a directly observed employer-to-employer transition.

## Validation and memory accounting

The integration test writes the same deterministic panel with one-worker, nine-worker, and all-worker blocks and compares every value, row order, missing-value rule, and storage type. It also verifies `isid workerid time`, unchanged RNG state, and observation-count failures.

The spike exposes conservative final-panel and peak-working-byte estimates. Benchmarks record Stata's elapsed time and allocated memory alongside that estimate. The estimate includes the final Stata panel, five double-precision block vectors, and four worker-length state vectors; later DGP modules must extend the accounting for their own live state rather than silently relying on the toy estimate.

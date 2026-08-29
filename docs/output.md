# Block-output implementation

The first output spike establishes the common write strategy before a DGP is introduced.

## Strategy

- Calculate and validate `workers × periods` before allocating observations.
- Cap the provisional common path at the lower of Stata's theoretical observation limit and 2,147,483,647 observations.
- Create final Stata variables once with explicit storage types.
- Assemble deterministic worker-major blocks and write each column with vectorized `st_store()` calls.
- Target at most 250,000 output rows per adaptive block, while never splitting a worker's requested periods across blocks.
- Retain only worker-length dynamic state and the current output block in Mata; do not retain a full second panel copy.
- Finalize sorting, labels, characteristics, and any cross-block metadata only after all blocks are written.

The toy writer uses `long` IDs and time, `byte` employment status, and `double` wages. Those types validate the mechanism but do not yet freeze every final output type.

The private lifecycle integration now creates the complete frozen panel through the shared output module: core identifiers/state/value columns, spell and tenure columns, finalized flow indicators, latent transition counts, and optional truth columns. It applies explicit labels and `%ty`, `%tq`, or `%tm` formatting, verifies `isid workerid time`, preflights every complete worker block before creating Stata data, and clears partial output after an injected write failure. The internal lifecycle result is intentionally small and currently materialized; real DGP integration must stream lifecycle blocks rather than retain that full matrix.

`src/fesim_flows.mata` finalizes one or more complete worker histories at a time. `newjob`, `from_unemp`, `jobtojob`, and `ntransitions` are missing in each worker's first output period because no prior observation exists. `to_unemp` is defined from the current and next observed states and is missing in the last period. A changed spell marks `newjob=1` even when the observed firm ID is unchanged, while `jobtojob=1` requires employment at different observed firms in adjacent periods. This distinguishes a same-firm return after nonemployment or hidden within-period moves from a directly observed employer-to-employer transition.

## Validation and memory accounting

The integration test writes the same deterministic panel with one-worker, nine-worker, and all-worker blocks and compares every value, row order, missing-value rule, and storage type. It also verifies `isid workerid time`, unchanged RNG state, and observation-count failures.

The spike exposes conservative final-panel and peak-working-byte estimates. Benchmarks record Stata's elapsed time and allocated memory alongside that estimate. The estimate includes the final Stata panel, five double-precision block vectors, and four worker-length state vectors; later DGP modules must extend the accounting for their own live state rather than silently relying on the toy estimate.

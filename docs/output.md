# Block-output implementation

The first output spike establishes the common write strategy before a DGP is introduced.

## Strategy

- Calculate and validate `workers × periods` before allocating observations.
- Cap the provisional common path at the lower of Stata's theoretical observation limit and 2,147,483,647 observations.
- Create final Stata variables once with explicit storage types.
- Assemble deterministic worker-major blocks and write each column with vectorized `st_store()` calls.
- Target at most 250,000 output rows per adaptive block, while never splitting a worker's requested periods across blocks.
- Retain only worker-length dynamic state and the current output block in Mata; do not retain a full second panel copy.
- Finalize sorting, labels, characteristics, and flow variables only after all blocks are written.

The toy writer uses `long` IDs and time, `byte` employment status, and `double` wages. Those types validate the mechanism but do not yet freeze every final output type.

## Validation and memory accounting

The integration test writes the same deterministic panel with one-worker, nine-worker, and all-worker blocks and compares every value, row order, missing-value rule, and storage type. It also verifies `isid workerid time`, unchanged RNG state, and observation-count failures.

The spike exposes conservative final-panel and peak-working-byte estimates. Benchmarks record Stata's elapsed time and allocated memory alongside that estimate. The estimate includes the final Stata panel, five double-precision block vectors, and four worker-length state vectors; later DGP modules must extend the accounting for their own live state rather than silently relying on the toy estimate.

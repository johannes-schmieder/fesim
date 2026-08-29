# Simple AKM implementation

The normative simple-AKM model and frozen stylized defaults are in [`DESIGN.md`](../DESIGN.md#8-dgp-1-simple-akm). This note records the qualified implementation boundary.

## Population layer

`src/fesim_akm_simple.mata` implements the scientific population, state-transition, and wage layers. For a supplied component RNG state its population layer:

- assigns consecutive, persistent worker and firm identifiers;
- draws one standard normal worker primitive and scales it by `sd_worker`;
- draws one standard normal firm primitive and scales it by `sd_firm`;
- draws an independent standard normal attraction primitive on the firm-primitives stream and scales it by `firm_size_sd`;
- normalizes attraction weights with a max-shifted softmax.

The worker-primitives and firm-primitives streams are distinct from wage shocks, mobility events, and destination draws. Additional draws on those other streams therefore do not change the population. Explicit-seed population calls restore the caller's RNG generator and state through the shared RNG manager.

`firm_size_sd=0` returns exact uniform weights. For extreme positive scales, relative log weights are floored at `-700` after max shifting. This avoids overflow and finite-precision zeros while preserving ordering and normalized positive mass. Invalid or overflowed worker/firm values are rejected by the shared population validator.

The internal population moment vector reports worker-effect mean/sample SD/sample variance, firm-effect mean/sample SD/sample variance, minimum and maximum attraction weight, and attraction-weight HHI. Its companion target vector records mean zero and the requested worker/firm standard deviations and variances; attraction-weight summaries have no fixed finite-sample targets.

## Initial state

The internal initial-state layer supports the three frozen common modes:

- `stationary` constructs the actual interval transition matrix over unemployment and every firm, including attraction-weighted entry and attraction-weighted direct moves conditional on excluding the current firm. It samples the stationary joint state and initializes employed tenure from the geometric stationary job-age distribution based on the effective interval `EU+EE` exit probability.
- `random` independently employs workers with probability 0.5, assigns firms using primitive attraction weights, initializes tenure at zero, and is valid only with positive burn-in.
- `allunemployed` sets every worker nonemployed with a zero internal spell counter and consumes no initialization draws.

When job exit is zero, stationary tenure is set to zero and stationarity applies only to employment and firm state. When both `EU` and `UE` are zero, the employment stationary distribution is not unique and stationary initialization is rejected. Employment/tenure draws and firm-assignment draws use separate component streams; neither changes the caller's Stata RNG state for an explicit seed.

## Interval mobility and burn-in

Each interval draws one event uniform and one destination uniform for every worker. Employed workers face the converted competing `EU` and `EE` probabilities; unemployed workers face the converted `UE` probability. Direct movers sample attraction weights conditional on excluding their current employer, while entrants sample the primitive weights. At most one transition occurs per simple-AKM interval.

Stayers increment job tenure or unemployment duration. `EU` retains the completed spell counter and starts unemployment duration at zero. `UE` increments the spell counter and starts job tenure at zero. `EE` likewise increments the spell counter and resets tenure without an intervening unemployment row. The wage-shock stream cannot affect mobility events; destination-stream perturbations can change firms but not employment events, spell changes, or durations.

Burn-in repeats this exact advance rule for the requested number of discrete output-clock intervals.

## Wage components

For each retained period the module consumes one standardized wage-stream draw per worker and uses it only for employed workers. This fixes wage-stream consumption independently of employment counts and future output blocking. Employed log wages equal `mu + alpha + psi + wage_trend * elapsed_years + epsilon`; `xb_true` and `match_true` are zero, and there is no observation error, so `lnwage_true` equals `lnwage`. Nonemployment retains `alpha_true` and the deterministic time component but leaves firm-, wage-, and job-specific components missing.

Elapsed years are measured from the first retained observation, not from initialization or burn-in. The wage helper returns named truth components plus realized and target epsilon moments.

## Public streaming handler

`src/fesim_akm_handler.mata` composes the qualified population, initialization, burn-in, transition, and wage routines. It retains worker-length population and state objects, writes each retained period directly into worker-major Stata rows, and finalizes observed flows in bounded complete-worker blocks. It never constructs a second full worker-period panel in Mata.

The public command accepts both `dgp(akm) preset(simple)` and `dgp(akmsimple)`. It attaches the common metadata and realized-moment schema, records the requested alias separately from the canonical DGP, and preserves economic output across alias spelling, reporting mode, truth suppression, and block size. During streaming it accumulates employed epsilon and worker-firm cross-products and marks active firms. This supplies the ten weighted component/truth rows in `r(moments)` and their mean/SD/variance/covariance targets in `r(targets)` even under `truth(none)`, without retaining employed-observation vectors.

The finalized panel is contracted to unique observed worker-firm matches for bipartite component diagnostics. `connectivity(keep)` returns those diagnostics without filtering. `connectivity(largest)` retains complete histories for selected workers and recomputes common and truth moments on that returned sample. Exact graph, tie-breaking, denominator, and `r(network)` semantics are in [`docs/network.md`](network.md).

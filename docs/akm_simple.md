# Simple AKM implementation

The normative simple-AKM model and frozen stylized defaults are in [`DESIGN.md`](../DESIGN.md#8-dgp-1-simple-akm). This note records the qualified implementation boundary.

## Population layer

`src/fesim_akm_simple.mata` currently implements the worker and firm population only. For a supplied component RNG state it:

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

The module does not yet simulate mobility, apply burn-in, generate wages, materialize public output, or expose a public DGP. Those are subsequent P2 stages.

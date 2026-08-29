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

The population module does not yet initialize employment, assign workers to firms, simulate mobility, generate wages, or expose a public DGP. Those are subsequent P2 stages.

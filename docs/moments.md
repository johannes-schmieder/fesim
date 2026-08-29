# Common moments

The installed internal `_fesim_moments` ado is the common Stata-facing moment engine. It validates the balanced worker-period and flow-variable contracts, computes realized moments without changing the dataset or RNG state, and returns a one-column `r(moments)` matrix with stable row names.

## Observation units

- Employment is averaged over all worker-period observations.
- EU, UE, and EE rates use adjacent observations and condition on the appropriate origin state. Undefined boundary observations do not enter their risk sets.
- Log-wage means, sample standard deviations, and p10/p50/p90 use employed observations.
- Firm-size means, sample standard deviations, and p10/p50/p90/p99 pool active firm-period employment counts.
- Firm concentration is the equally weighted mean of output-period HHIs over periods with positive employment.
- Movers have at least two distinct observed employers; stayers have exactly one. Their shares condition on ever employment, while never-employed workers are reported separately.

The exact row order is normative in [`DESIGN.md`](../DESIGN.md#76-common-moment-schema).

## Truth moments

`src/fesim_moments.mata` computes the fixed truth block supplied by a DGP. Worker effects are counted once per worker, active-firm effects once per active firm, and idiosyncratic shocks once per employed observation. Worker-firm covariance is employment weighted. All variances and covariance use the sample denominator.

These diagnostics describe the generated latent objects, so their availability does not depend on whether `truth(none)`, `truth(basic)`, or `truth(full)` exposes row-level truth variables in the returned dataset.

The public simple-AKM handler implements those conventions with streaming sufficient statistics. Under `connectivity(keep)`, it gives worker effects one observation per simulated worker, marks and uses each active firm's effect once, and accumulates epsilon and worker-firm cross-products over employed worker-periods. These rows and their target table therefore require no full employed-observation buffer.

Under `connectivity(largest)`, the graph filter changes the returned sample, so the truth block is recomputed from the retained complete histories: worker effects once per retained worker, firm effects once per retained active firm, and shock/covariance inputs over retained employed observations. This recomputation also occurs under `truth(none)` before temporary truth columns are removed.

## Target comparisons

An applicable one-column target matrix selects rows by the common moment names. The returned table has columns `target`, `realized`, `difference`, and `relative_difference`. Difference is realized minus target; relative difference divides by the absolute target and is missing for a zero target.

The public `akm/simple` route supplies both its truth block and component targets to this engine. The private deterministic lifecycle remains an independent integration fixture.

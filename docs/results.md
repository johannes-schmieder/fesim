# Common metadata and returned results

The internal `_fesim_finalize` ado is the single common boundary between a completed simulation dataset and Stata metadata, `r()` results, and compact display. It is installed for use by the eventual public execution path but is not itself a public command or a DGP.

Before changing metadata, the finalizer validates the worker-period key, requested dimensions, named result matrices, scalar bounds, and stage runtimes. It then attaches every required characteristic from `DESIGN.md` Section 7.5, plus the Stata version, RNG method, network design, and truth mode required for reproducibility. The resolved design is returned as `r(network_design)` and stored in `_dta[fesim_network_design]`.

The common scalar and macro names follow `DESIGN.md` Section 16. Diagnostics not yet computed by the selected route are returned as missing scalars; optional target, network/leave-out, solver, duration, and bridge matrices are omitted when not applicable. All public AKM presets supply the 21-row `r(network)` matrix, the 19-row `r(leaveout)` matrix, and common component/share scalars documented in [`docs/network.md`](network.md). The network and leave-out matrices are validated and returned together: `r(network)` retains generated/returned descriptive graph summaries, while `r(leaveout)` reports the current returned panel's KSS-aligned worker-history set and complete-match vulnerability audit. `akm/stylized` and `akm/germany_chk_2002_2009` additionally supply a 12-row `r(durations)` matrix in years. The Germany preset supplies a ten-row target comparison including `cov_alpha_psi_true`; the generic stylized preset retains its nine-row marginal target block. `network(bridges)` supplies `r(bridges_imposed)` and the exact eight-column `r(bridges)` intervention ledger, while other designs return a zero bridge scalar and omit the matrix. `network(ladder)` records its four registered controls in `r(parameters)` and the resolved design in `r(network_design)` without adding block truth or an intervention ledger. Parameter and moment matrices are required to have stable row or column names before they can be returned. The upstream common moment and target schemas are documented in [`docs/moments.md`](moments.md).

`report` and `noreport` call the same finalization path. Reporting only prints a compact view after metadata and returns are assembled. The canonical `r(command)` and `_dta[fesim_command]` describe the scientific execution configuration and exclude the reporting-only switch, and stage runtimes exclude display time. Consequently, display choice changes neither data, metadata, RNG state, nor returned values.

The public simple-AKM route measures `r(runtime_simulate)` around population/state generation, transitions, wages, direct Stata writes, and flow finalization. `r(runtime_output)` covers observed graph construction/filtering, retained-sample truth recomputation when applicable, and common moments. `r(runtime_total)` is their sum; `r(runtime_solve)` is zero because this DGP has no solve stage. Configuration, source loading, metadata finalization, and report display are outside these stage timers.

Timing uses two currently unused native Stata/Mata timer slots. The runtime helper scans from slot 100 downward, never claims a slot that has been started, and clears only slots it claimed. If fewer than two slots are free, runtime values safely fall back to zero rather than changing a caller timer. Success and failure tests verify that occupied caller timers survive and claimed slots are released.

## BM-specific results

The public canonical BM route uses the common metadata, parameters, moments,
durations, graph, leave-out, and stage-timing contract. Its additional named
matrices are `r(solver)` (22-by-1), `r(bm_flows)` (4-by-4), and `r(bm_firms)`
(10-by-3 firm means/minima/maxima). Exact definitions and original-economy versus
returned-sample scopes are in D-042 and the canonical BM help section. No AKM
truth effects or inappropriate AKM targets are fabricated. Basic/full truth
changes output columns only; BM diagnostics are available with every truth mode.

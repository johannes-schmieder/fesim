# Common metadata and returned results

The internal `_fesim_finalize` ado is the single common boundary between a completed simulation dataset and Stata metadata, `r()` results, and compact display. It is installed for use by the eventual public execution path but is not itself a public command or a DGP.

Before changing metadata, the finalizer validates the worker-period key, requested dimensions, named result matrices, scalar bounds, and stage runtimes. It then attaches every required characteristic from `DESIGN.md` Section 7.5, plus the Stata version, RNG method, and truth mode required for reproducibility.

The common scalar and macro names follow `DESIGN.md` Section 16. Diagnostics not yet computed by the selected route are returned as missing scalars; optional target, network, and solver matrices are omitted when not applicable. The public simple-AKM route supplies the network matrix and common component/share scalars documented in [`docs/network.md`](network.md). Parameter and moment matrices are required to have stable row or column names before they can be returned. The upstream common moment and target schemas are documented in [`docs/moments.md`](moments.md).

`report` and `noreport` call the same finalization path. Reporting only prints a compact view after metadata and returns are assembled. The canonical `r(command)` and `_dta[fesim_command]` describe the scientific execution configuration and exclude the reporting-only switch, and stage runtimes exclude display time. Consequently, display choice changes neither data, metadata, RNG state, nor returned values.

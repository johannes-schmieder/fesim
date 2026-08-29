# Observed connectivity diagnostics

The installed internal `_fesim_network` ado constructs the observed bipartite worker-firm graph after the panel and common flow variables are finalized. It contracts employed observations to one sorted row per unique worker-firm match and passes that compressed edge list, including the match's employed-observation count, to `src/fesim_network.mata`. The Mata layer uses union-find and never creates a dense worker-by-firm adjacency matrix.

## Nodes, edges, and denominators

Worker nodes are workers observed employed at least once. Firm nodes are firms observed active at least once. Each unique observed worker-firm match is one edge, regardless of its duration. Never-employed workers and inactive firms have no component membership and do not enter component counts or shares.

The largest-component observation share weights edges by their employed worker-period counts. Its worker and firm shares use ever-employed workers and active firms as their respective denominators. A component ID is the smallest global node ID in the component, with worker nodes numbered first; consequently every nonempty component's ID is its smallest worker ID.

The selected largest component maximizes, in order, employed observations, workers, firms, and then the negative component ID. This makes every tie deterministic.

## Returned matrix

`r(network)` has columns `generated` and `returned` and the following stable rows:

1. `components`
2. `edges`
3. `employed_observations`
4. `workers`
5. `firms`
6. `largest_component_id`
7. `largest_edges`
8. `largest_observations`
9. `largest_workers`
10. `largest_firms`
11. `largest_observation_share`
12. `largest_worker_share`
13. `largest_firm_share`

With `connectivity(keep)`, both columns describe the unfiltered generated sample and are identical. If the panel has no employment, component, edge, worker, and firm counts are zero; the largest component ID and its shares are missing.

With `connectivity(largest)`, `generated` preserves the pre-filter diagnostics. `returned` describes the retained sample: its component count is one, rows 2–5 equal the selected component's rows 7–10, and all three shares are one. The original selected component ID and largest-component counts remain available. The common scalar network returns describe the `returned` column.

## Filtering and moments

`connectivity(largest)` retains complete worker histories, including nonemployment periods, for workers in the selected component. Worker IDs are not renumbered. The result remains balanced and sorted by `workerid time`; `r(N_workers)` is the retained worker count, while `r(parameters)["workers","value"]` remains the requested generated-population size.

Common and truth moments are computed for the retained sample. When the user requests `truth(none)`, the simple-AKM route temporarily generates the basic truth columns, recomputes the retained-sample truth moments after filtering, and removes those columns before returning data. This changes neither scientific draws nor the visible truth contract.

A panel with no observed employment rejects `connectivity(largest)` and restores the caller's prior data and RNG state. `connectivity(force)` remains unavailable because no scientific generation rule has been accepted; it fails before replacement or random draws.

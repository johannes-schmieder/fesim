# Observed network diagnostics

The installed internal `_fesim_network` ado constructs two observed graphs after the panel and common flow variables are finalized. The bipartite worker-firm graph supplies connected-component diagnostics. The undirected firm mobility graph supplies direct-move link diagnostics. Both are computed from the retained output panel; neither reconstructs unobserved events between output snapshots.

## Nodes, edges, and denominators

Worker nodes are workers observed employed at least once. Firm nodes are firms observed active at least once. Each unique observed worker-firm match is one edge, regardless of its duration. Never-employed workers and inactive firms have no component membership and do not enter component counts or shares.

The largest-component observation share weights edges by their employed worker-period counts. Its worker and firm shares use ever-employed workers and active firms as their respective denominators. A component ID is the smallest global node ID in the component, with worker nodes numbered first; consequently every nonempty component's ID is its smallest worker ID.

The selected largest component maximizes, in order, employed observations, workers, firms, and then the negative component ID. This makes every tie deterministic.

## Observed firm mobility graph

Firm nodes are the active firms defined above. An unordered firm pair is linked when at least one worker has adjacent output observations with `jobtojob == 1` between those firms. Link direction is pooled. The link weight is the number of such observed direct moves, so each qualifying adjacent output interval contributes one even if the internal monthly engine recorded additional latent events within that interval. Same-firm endpoint transitions, entries from unemployment, exits to unemployment, and latent events that do not appear as an observed direct move are not links.

`firms_no_movers` counts active firms incident to no observed mobility link. `firm_links` counts distinct unordered linked pairs. `edge_weight_p10`, `edge_weight_p50`, `edge_weight_p90`, and `edge_weight_p99` are percentiles across the distinct links' weights using Stata's default percentile convention: for probability `p`, average order statistics `Np` and `Np + 1` when `Np` is an integer and otherwise use order statistic `ceil(Np)`. The percentiles are missing when there are no links.

These are descriptive observed-graph summaries. They do not establish articulation, bridge, leave-one-worker, leave-one-match, or KSS leave-out connectedness.

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
14. `firms_no_movers`
15. `firm_links`
16. `edge_weight_p10`
17. `edge_weight_p50`
18. `edge_weight_p90`
19. `edge_weight_p99`

With `connectivity(keep)`, both columns describe the unfiltered generated sample and are identical. If the panel has no employment, component, edge, worker, firm, no-mover, and firm-link counts are zero; the largest component ID, its shares, and the link-weight percentiles are missing.

With `connectivity(largest)`, `generated` preserves the pre-filter diagnostics. `returned` describes the retained sample: its component count is one, rows 2–5 equal the selected component's rows 7–10, and all three shares are one. Rows 14–19 are recomputed from the retained workers' complete output histories, rather than copied from the generated graph. The original selected component ID and largest-component counts remain available. The common scalar component/share returns describe the `returned` column; the expanded mobility summaries are exposed through `r(network)`.

## Filtering and moments

`connectivity(largest)` retains complete worker histories, including nonemployment periods, for workers in the selected component. Worker IDs are not renumbered. The result remains balanced and sorted by `workerid time`; `r(N_workers)` is the retained worker count, while `r(parameters)["workers","value"]` remains the requested generated-population size.

Common and truth moments are computed for the retained sample. When the user requests `truth(none)`, the simple-AKM route temporarily generates the basic truth columns, recomputes the retained-sample truth moments after filtering, and removes those columns before returning data. This changes neither scientific draws nor the visible truth contract.

A panel with no observed employment rejects `connectivity(largest)` and restores the caller's prior data and RNG state. `connectivity(force)` remains unavailable because no scientific generation rule has been accepted; it fails before replacement or random draws.

# Network stress designs and observed diagnostics

## Simulated destination designs

`network(random)` is the frozen compatibility default. It uses the existing
attraction-weighted initialization/UE kernels and current-firm-excluding EE
kernels without drawing community assignments.

`network(blocks)` assigns workers and firms independently to balanced
communities: community sizes differ by at most one, but membership is randomly
permuted on isolated stream 109. A worker's permanent home community governs
origin-free initialization and UE assignments. Direct EE moves use the current
firm's community. In either public AKM preset, the relevant ordinary
destination weight is multiplied by `exp(block_log_bonus)` when the destination
is in the reference community. Defaults are four communities and `log(9)`;
`block_log_bonus=0` delegates to the exact frozen random destination rule.

The common option is `network(random|blocks|bridges|ladder)`. Network scalars remain
inside `parameters()`; supplying a network parameter under an irrelevant
design is an error. Under `truth(full)`, `network(blocks)` and
`network(bridges)` add `worker_block_true` and `firm_block_true`. Worker truth is
permanent; firm truth is the current employer's community and is missing while
unemployed. `r(network_design)` and `_dta[fesim_network_design]` record the
resolved design.

`network(bridges)` begins from strict blocks rather than a finite log bonus.
Initialization and UE assignments stay in the worker's permanent home block;
ordinary EE destinations stay in the current firm's block. Each block must
therefore contain at least two firms. The design first replays the retained
mobility path on copied state and component-RNG records to identify each
worker's first eligible EE event. Within each required source block it selects
eligible workers by the independently drawn network priority. The economic run
then consumes the ordinary event and destination streams once and redirects
only each selected event's destination. No hazard, event time, spell increment,
transition count, or extra random draw is created.

The default plan has `bridge_count=block_count-1` and links adjacent labels
1-2, 2-3, ..., B-1-B. Extra bridges cycle deterministically through those
pairs. Workers are distinct over the complete plan. A target firm is sampled
from the prescribed target block with the selected DGP's ordinary conditional
weights and the same destination uniform already consumed by the EE event. If
the retained simulation lacks enough eligible distinct workers, the command
fails and restores caller data and RNG state.

Every bridge run adds `nbridges_imposed`, the worker/output-interval count, and
returns `r(bridges_imposed)` plus an exact `r(bridges)` ledger. Its columns are
`bridge_id`, `workerid`, `output_period`, `internal_period`, `source_firm`,
`target_firm`, `source_block`, and `target_block`. The dataset characteristic
`fesim_bridges_imposed` records the total. Full truth supplies the block IDs;
the ledger and interval counts are available under every truth mode.

These block labels and bridge transitions are imposed simulation-design
objects. Completing the adjacent block-level chain does not establish a
leave-one-worker, leave-one-match, or KSS leave-out result in the realized
worker-firm graph. The observed-graph articulation and bridge-link counts below
are separate descriptive diagnostics.

`network(ladder)` changes only the destination of an ordinary EE event. Firms
are ranked in both public routes by persistent wage effect `psi_j`, using
percentile midranks so ties are lateral. A candidate within `ladder_band` of
the origin rank is lateral; candidates below and above that band are downward
and upward. Defaults are `.10`, `.20`, and `.70` for downward, lateral, and
upward shares and `.10` for the band. Unavailable directions are removed and
the configured shares are renormalized over directions with positive ordinary
mass. Within direction, the simple route retains attraction weights and the
stylized route retains its type, quality, sorting, and asymmetric-distance
kernel. The same existing destination uniform samples the mixture. No event,
initialization, UE, wage, or extra RNG draw is introduced. The design is a
reduced-form wage ladder, not a structural BM or revealed-preference model.

The installed internal `_fesim_network` ado constructs two observed graphs after the panel and common flow variables are finalized. The bipartite worker-firm graph supplies connected-component diagnostics. The undirected firm mobility graph supplies direct-move link diagnostics. Both are computed from the retained output panel; neither reconstructs unobserved events between output snapshots.

## Nodes, edges, and denominators

Worker nodes are workers observed employed at least once. Firm nodes are firms observed active at least once. Each unique observed worker-firm match is one edge, regardless of its duration. Never-employed workers and inactive firms have no component membership and do not enter component counts or shares.

The largest-component observation share weights edges by their employed worker-period counts. Its worker and firm shares use ever-employed workers and active firms as their respective denominators. A component ID is the smallest global node ID in the component, with worker nodes numbered first; consequently every nonempty component's ID is its smallest worker ID.

The selected largest component maximizes, in order, employed observations, workers, firms, and then the negative component ID. This makes every tie deterministic.

## Observed firm mobility graph

Firm nodes are the active firms defined above. An unordered firm pair is linked when at least one worker has adjacent output observations with `jobtojob == 1` between those firms. Link direction is pooled. The link weight is the number of such observed direct moves, so each qualifying adjacent output interval contributes one even if the internal monthly engine recorded additional latent events within that interval. Same-firm endpoint transitions, entries from unemployment, exits to unemployment, and latent events that do not appear as an observed direct move are not links.

`firms_no_movers` counts active firms incident to no observed mobility link. `firm_links` counts distinct unordered linked pairs. `edge_weight_p10`, `edge_weight_p50`, `edge_weight_p90`, and `edge_weight_p99` are percentiles across the distinct links' weights using Stata's default percentile convention: for probability `p`, average order statistics `Np` and `Np + 1` when `Np` is an integer and otherwise use order statistic `ceil(Np)`. The percentiles are missing when there are no links.

`articulation_firms` counts active firms whose deletion with all incident links
increases the number of connected components in the undirected firm graph.
`graph_bridge_links` counts distinct unordered firm links whose deletion
increases that component count. Both use the unweighted distinct-link topology;
move counts do not change their status. Isolated active firms are not
articulation firms, and both counts are zero when the graph has no links. The
iterative depth-first traversal runs in linear time after link construction and
does not allocate a dense firm-by-firm matrix.

These remain descriptive observed-graph summaries. They do not establish
leave-one-worker, leave-one-match, or KSS leave-out connectedness.

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
20. `articulation_firms`
21. `graph_bridge_links`

With `connectivity(keep)`, both columns describe the unfiltered generated sample and are identical. If the panel has no employment, component, edge, worker, firm, no-mover, and firm-link counts are zero; the largest component ID, its shares, and the link-weight percentiles are missing.

With `connectivity(largest)`, `generated` preserves the pre-filter diagnostics. `returned` describes the retained sample: its component count is one, rows 2–5 equal the selected component's rows 7–10, and all three shares are one. Rows 14–21 are recomputed from the retained workers' complete output histories, rather than copied from the generated graph. The original selected component ID and largest-component counts remain available. The common scalar component/share returns describe the `returned` column; the expanded mobility summaries are exposed through `r(network)`.

## Filtering and moments

`connectivity(largest)` retains complete worker histories, including nonemployment periods, for workers in the selected component. Worker IDs are not renumbered. The result remains balanced and sorted by `workerid time`; `r(N_workers)` is the retained worker count, while `r(parameters)["workers","value"]` remains the requested generated-population size.

Common and truth moments are computed for the retained sample. When the user requests `truth(none)`, the simple-AKM route temporarily generates the basic truth columns, recomputes the retained-sample truth moments after filtering, and removes those columns before returning data. This changes neither scientific draws nor the visible truth contract.

A panel with no observed employment rejects `connectivity(largest)` and restores the caller's prior data and RNG state. `connectivity(force)` remains unavailable because no scientific generation rule has been accepted; it fails before replacement or random draws.

# Development architecture

The normative architecture is in [`DESIGN.md`](../DESIGN.md). This note records only implementation details established by the current source.

## Current candidate

All eight presets dispatch through five scientific engines: interval AKM,
monthly AKM, two-group pay-gap, canonical continuous-time BM, and CPV bargaining. The public
parser/configuration boundary validates before mutation; source loading,
component RNG, streaming output, graph filtering, truth/moments, and final
metadata are shared. `_fesim_schema.ado` supplies discovery inventories and
scientific scope; numeric schemas remain in `fesim_registry.ado`.
Public API level 1 is unchanged; the internal Mata API is now 35. Runtime installs
only authoritative Stata/Mata source. See [compatibility](compatibility.md).

## Historical evolution from Checkpoint 2

The checkpoint narrative below records earlier boundaries. Statements such as
“discovery-only”, “not yet”, and earlier API numbers describe those checkpoints,
not the current eight-preset candidate.

The public `fesim.ado` layer performs subcommand detection, discovery dispatch, and data-safety enforcement. It delegates DGP and preset resolution, defaults, overrides, and validation before it considers replacing loaded data.

`fesim_registry.ado` is the authoritative source for canonical DGP names, aliases, presets, calibration classifications, configuration availability, and all public AKM scalar schemas. Each scalar record supplies type, units, bounds, bound closure, applicability, default value and source, and allowed input routes. Planned presets remain discoverable but cannot be configured or simulated.

`fesim_config.ado` is the shared resolver. It merges package/preset defaults with named common options and `parameters()` values; rejects duplicate, unknown, inapplicable, or invalid inputs; applies cross-parameter checks; and returns both a stable text serialization and a parameter matrix. Alias spelling is deliberately excluded from the serialization, so `akmsimple` and `akm, preset(simple)` yield identical canonical configurations. Model-parameter changes reclassify the calibration as `stylized_modified`; sample-layout changes do not.

The resolver and discovery commands neither set a seed nor request random draws. At Checkpoint 2, valid simulation syntax exited with return code 498 after configuration validation and before data clearing or RNG use. Checkpoint 15 superseded that temporary boundary by opening the qualified public `akm/simple` route described below.

## Mata source and build

Mata source files under `src/` are authoritative. `src/build_mlib.do` compiles the current `fesim_*()` functions into an ignored development library at `build/lfesim.mlib`, clears Mata, reindexes libraries, and calls the compiled API as a load test.

The development library is not distributed by `fesim.pkg`. The package installs authoritative Mata source and loads it in a fixed dependency order when a compatible indexed library is unavailable. A loader invoked from a checkout first uses that checkout's colocated `src/` tree, so an older installed package cannot supply a mixed-API source file; an installed loader falls back to the normal ado-path lookup. This source-only runtime strategy was fixed at Checkpoint 15 and is exercised by the clean-install and stale-source-precedence suites.

Checkpoint 3 adds two qualified shared prototypes to that library. `src/fesim_rng.mata` manages fixed `mt64s` component states without exposing long RNG-state strings to ado code; details are in [`docs/rng.md`](rng.md). `src/fesim_output.mata` validates observation counts, computes conservative memory estimates, and writes deterministic worker-major blocks through vectorized `st_store()` calls; details are in [`docs/output.md`](output.md). Neither module yet dispatches a DGP.

Checkpoint 4 adds `fesim_time.ado` as the authoritative Stata-facing frequency/start normalizer and `src/fesim_time.mata` for abstract period vectors and annual-probability conversion. The configuration resolver delegates date parsing to this module and returns the Stata time format, interval unit, internal-clock label, start/end values, periods per year, and year fraction. EU and EE are converted jointly as competing risks; UE uses the single-risk conversion. These routines do not inspect calendar days, data, or RNG state.

Checkpoint 5 expands the internal Mata API to version 2. `src/fesim_types.mata` defines composed configuration, population, dynamic-state, result, and handler structures with explicit schema versions. `src/fesim_lifecycle.mata` supplies constructors and validation routines plus deterministic internal implementations of the required lifecycle stages. `src/fesim_dispatch.mata` admits only the private `_toy/deterministic` handler and returns a validated worker-major observation matrix; it never creates, labels, or writes Stata variables. Repeated dispatch calls build fresh local structures, and tests deliberately mutate one returned result to prove later and prior results do not share mutable state. This handler qualifies the shared contract only and must not appear in the public registry.

Checkpoint 6 raises the internal Mata API to version 3 and integrates that private result with `src/fesim_output.mata`. The shared writer alone creates the frozen core and flow-placeholder variables, applies storage types, labels and Stata time formats, writes worker blocks, checks the panel key, and optionally adds deterministic basic/full truth columns. A diagnostic failure hook proves that partial output is cleared; it is internal test machinery, not a public option. The private result currently retains a full small observation matrix, so this integration qualifies interfaces and invariants rather than superseding the streaming requirement for real DGPs.

Checkpoint 7 raises the internal Mata API to version 4 and adds `src/fesim_flows.mata`. The shared pure finalizer accepts complete worker histories within a bounded writer block, validates their common observed-state contract, constructs adjacent-observation flows, and masks undefined boundary values. The writer stores those finalized values rather than handler-created variables. Spell changes capture new jobs even when endpoint firm IDs agree; direct job-to-job moves require different adjacent observed firms; the latent transition count is retained separately.

Checkpoint 8 adds the installed internal ado `_fesim_finalize`. After a simulation route has written and validated its dataset, this common boundary attaches characteristics, returns the stable scalar/macro/matrix contract, records supplied stage runtimes, and optionally prints a compact report. Report mode is applied only after the canonical scientific command, metadata, and results are assembled, so `report` and `noreport` are invariant apart from display. Details are in [`docs/results.md`](results.md).

Checkpoint 9 raises the internal Mata API to version 5 and adds `src/fesim_moments.mata` plus the installed internal ado `_fesim_moments`. The Mata layer computes DGP-supplied truth moments with fixed sample weighting; the ado layer validates the finalized panel, computes the fixed common realized schema and optional target table, and preserves both data and RNG state. The private integration route now passes these results into `_fesim_finalize`. Details are in [`docs/moments.md`](moments.md).

Checkpoint 10 adds a GitHub-hosted static lane and a separate licensed-Stata exact-source wrapper. Static checks validate package/source/test registration and reject tracked generated artifacts without claiming Stata execution. The licensed wrapper derives `HEAD` from a clean checkout and verifies the generated receipt against that same repository, preventing a requested or stale SHA from being accepted as exact evidence. Details are in [`docs/ci.md`](ci.md).

Checkpoint 11 raises the internal Mata API to version 6 and the shared population schema to version 2. The population container now carries normalized firm attraction weights. `src/fesim_akm_simple.mata` supplies the first scientific implementation: persistent normal worker/firm effects, independent numerically stable attraction weights, and named population target/realized moments. It remains below the public dispatch boundary until initialization, mobility, wages, output, and diagnostics are qualified. Details are in [`docs/akm_simple.md`](akm_simple.md).

Checkpoint 12 raises the internal Mata API to version 7 and the dynamic-state schema to version 3. Unemployed workers may now carry a zero internal spell counter, while observed spell IDs remain missing. The simple-AKM initial-state layer constructs the exact unemployment-plus-firm interval chain, samples stationary job age, and implements the approved random and all-unemployed diagnostic starts. It remains below public dispatch pending mobility, wages, and output qualification.

Checkpoint 13 raises the internal Mata API to version 8, the dynamic-state schema to version 4, and the simple-AKM module schema to version 2. Dynamic state now carries unemployment duration. The AKM module advances competing employment exits, entries, direct firm moves, spell counters, tenure, unemployment duration, current deterministic value, and latent transition counts on isolated streams, with a repeated-advance burn-in path. Public dispatch remains closed pending wages and output qualification.

Checkpoint 14 raises the internal Mata API to version 9 and the simple-AKM module schema to version 3. The wage layer returns the employed wage plus the seven basic truth components, consumes a fixed one draw per worker-period, preserves nonemployment missingness, and reports realized/target epsilon moments. Public dispatch remains closed pending real-handler output integration.

Checkpoint 15 raises the internal Mata API to version 10 and the output schema to version 4. `src/fesim_akm_handler.mata` is the first public scientific handler: it composes the simple-AKM layers, streams retained periods directly into the final Stata panel, and delegates bounded flow finalization to the common output module. `fesim.ado` validates and resolves all configuration before mutation, records the actual component-stream master seed, restores data and RNG on handler failure, computes common moments, and passes the result through the common metadata boundary. Registry discovery now marks only `akm/simple` as qualified.

The runtime artifact strategy is source distribution. `fesim.pkg` installs the authoritative Mata files along with `_fesim_load.ado`; the loader uses an already indexed compatible library when available and otherwise executes the installed sources in dependency order. The clean-install suite explicitly removes the development library before its simulation smoke test. The ignored `build/lfesim.mlib` remains a fast development and exact-source qualification artifact, not an installed binary dependency.

Checkpoint 16 raises the internal Mata API to version 11 and simple-AKM handler schema to version 2. The streaming handler accumulates truth-component sufficient statistics and active-firm membership while writing periods, then supplies the common truth-moment vector and target vector to `_fesim_moments`. The public result includes weighted component rows and the four-column target comparison under every truth-output mode without a full employed-observation buffer.

Checkpoint 17 raises the internal Mata API to version 12 and adds `src/fesim_network.mata` plus the installed `_fesim_network` and `_fesim_truth` ado helpers. The network helper contracts the final employed panel to weighted unique matches, computes bipartite components with union-find, returns pre/post-filter diagnostics, and optionally retains complete histories from the deterministic largest component. The truth helper recomputes component moments on that retained sample, including when row-level truth is suppressed. Both helpers remain inside the public command's data/RNG rollback boundary. Details are in [`docs/network.md`](network.md).

Checkpoint 18 adds no runtime behavior. It freezes annual, quarterly, and monthly 24-observation simple-AKM panels with full data signatures, selected exact returns, repeated-call matrix equality, cleared-state reruns, and canonical/alias equality. Static test registration now includes `tests/regression/`. Details and portability limits are in [`docs/regression.md`](regression.md).

Checkpoint 19 adds no runtime behavior. It registers large-sample statistical tests for primitive normal effects, residuals, conditional transition rates, stationary employment, uniform firm assignment, random-mobility sorting, shock/mobility independence, and fixed-seed convergence. Every tolerance is based on a declared effective sample size and an eight- or ten-standard-error family-wide bound. Details are in [`docs/statistical_tests.md`](statistical_tests.md).

Checkpoint 20 adds no runtime behavior. It completes the simple-AKM user path in the help and README, documents simulation returns and truth variables, and adds a tested `examples/akmsimple.do` that uses only built-in `areg` for an estimator demonstration. Static test registration now includes `tests/docs/`.

Checkpoint 21 raises the internal Mata API to version 13 and adds `src/fesim_runtime.mata`. The public route claims only unused native timer slots, measures simulation and post-simulation diagnostics, releases its slots on success and failure, and leaves occupied caller timers unchanged. The exact-source benchmark harness records public-command time, internal stage time, dataset width, graph scale, and external process resource usage.

Checkpoint 26 begins the generic empirical-mobility engine and raises the internal Mata API to version 14. `src/fesim_hazards.mata` implements vectorized D-025 log-hazard construction, the log-one-plus duration transform in years, and stable one-risk and competing-risk conversion from annual hazards to arbitrary interval lengths. It is shared infrastructure only: no empirical preset is public until the remaining P3 lifecycle and DG-08 calibration work is complete.

Checkpoint 27 raises the internal Mata API to version 15 and adds `src/fesim_destinations.mata`. Five UE cumulative tables cover the fixed worker mobility types. Exact EE sampling uses firm-quality order, type-specific lower prefix and upper reverse-prefix tables, and stable log side totals to apply current-firm exclusion and the D-025 upward/downward kernel without allocating worker-by-firm probabilities. Sampling functions consume caller-supplied uniforms so the lifecycle retains ownership of the isolated destination RNG stream.

Checkpoint 28 raises the internal Mata API to version 16 and adds `src/fesim_empirical.mata`. The shared population schema now has optional worker mobility-type and firm-quality vectors; simple AKM leaves them missing while the empirical generator constructs the D-025 correlated latent indices. The empirical state advances on a fixed monthly clock with year-valued tenure and unemployment duration, exact duration-dependent hazards, grouped destinations, and fixed event/destination draw consumption. Random initialization uses a common cumulative attraction table with binary inverse-CDF lookup, and burn-in is specified in years but must resolve to whole months. This checkpoint is internal infrastructure: public empirical configuration and output remain unavailable until their later qualification checkpoint.

Checkpoint 29 raises the internal Mata API to version 17 and the output schema to version 5. D-026 opens `akm/stylized` and its `akmempirical` alias as an explicitly uncalibrated public route. `src/fesim_emp_handler.mata` composes the monthly lifecycle, sums latent transitions between output snapshots, and streams output-period-scaled tenure and unemployment duration; the common postprocessor returns their year-valued distribution diagnostics. Full truth adds worker mobility type and current-firm quality. The registry and machine-readable calibration table contain the same 23 model defaults, with CI testing their equality; any country-labeled calibration remains gated by DG-08.

Checkpoint 30 raises the internal Mata API to version 18 and the network schema to version 2. The shared network postprocessor now derives an undirected firm mobility graph directly from adjacent output observations marked `jobtojob`: it pools directions, collapses unordered firm pairs, counts active firms incident to no link, and reports distinct-link move-count percentiles. These rows are recomputed after largest-component filtering. The algorithm stores only the observed move pairs and their collapsed weights; it does not form dense firm-by-firm or worker-projection matrices and does not claim leave-out connectedness.

Checkpoint 31 raises the internal Mata API to version 19 and completes the behavior-preserving `network(random)` extraction. `src/fesim_destinations.mata` now owns common attraction-weighted inverse-CDF sampling and current-firm-excluding weighted sampling. Simple AKM delegates random initialization, entry, and direct moves to those shared primitives; empirical random initialization uses the same common sampler, while its grouped UE/EE tables continue to add the D-025 type, quality, sorting, and asymmetric-distance terms. Frozen panel signatures prove the extraction changes neither public route's draws nor output.

Checkpoint 32 raises the internal Mata API to version 20 and adds `src/fesim_network_design.mata`. Balanced independent worker and firm communities use isolated stream 109. Origin-free assignments reference the worker's permanent home block; EE assignments reference the current firm's block. The simple route computes its exact block-specific stationary distribution, while the stylized route expands the grouped destination tables by block without allocating worker-by-firm probabilities. A zero log bonus delegates both routes to their exact frozen random paths. Full truth adds worker/current-firm block IDs only for nonrandom designs, preserving the random dataset schema. The bridge design remains gated behind the subsequent exact destination-override checkpoint.

Checkpoint 33 raises the internal Mata API to version 21, network-design schema to 2, destination schema to 3, dynamic-state schema to 5, and output schema to 7. `network(bridges)` builds exact strict-block destination tables, replays copied retained mobility state to select globally highest-priority eligible distinct workers for its deterministic adjacent-block plan, and then overrides only those workers' planned EE destinations during the economic run. The returned state carries the already-consumed destination uniform across the handler boundary so the override introduces no draw. Output records per-worker interval counts under every truth mode and the common result boundary returns the exact eight-column intervention ledger. Both route handlers are schema-bumped for the planning/execution boundary.

Checkpoint 34 raises the internal Mata API to version 22 and the observed-network schema to 3 while retaining network-design schema 2. The distinct undirected observed firm graph now receives a memory-linear iterative depth-first traversal that counts articulation firms and graph-bridge links without recursion or a dense adjacency matrix. The diagnostics use the unweighted link topology, remain separate from design-imposed bridges, and are recomputed with all other mobility rows after `connectivity(largest)` filtering.

Checkpoint 35 raises the internal Mata API to version 23 and network-design schema to 3. `network(ladder)` builds deterministic tied midranks from persistent firm wage effects and transforms each ordinary current-firm-excluding EE probability vector into the approved downward/lateral/upward mixture. Simple AKM conditions attraction weights directly; stylized AKM conditions its existing grouped-kernel probabilities without constructing a worker-by-firm matrix. Thin transition wrappers call the qualified ordinary advance first and then replace only direct-move destinations with the already consumed destination uniform, preserving initialization, UE assignments, event draws, transition counts, and RNG consumption. Ladder truth adds no block variables.

Checkpoint 36 raises the internal Mata API to version 24 and the observed-network schema to 4. The compressed unique-match bipartite graph receives a second memory-linear iterative depth-first traversal that simultaneously identifies worker articulation vertices and complete-match bridges whose two sides both contain firms. The postprocessor repeatedly deletes complete histories of articulation workers and deterministically retains the largest remaining component until it reaches a robust fixed point or emptiness, then returns the stable 19-row `r(leaveout)` matrix. This conservative extension of KSS Algorithm 1 handles new articulation workers created by simultaneous pruning, distinguishes firm-disconnecting matches from stayer leaf edges, never allocates a dense graph, and does not filter the public panel.

Checkpoint 37 raises the internal Mata API to version 25 and the empirical-handler schema to 5. D-033 opens `akm/germany_chk_2002_2009` as a distinct targeted preset on the existing monthly empirical handler. Registry defaults and auditable calibration tables provide CHK worker, establishment, and residual dispersions; the handler optionally appends the direct employment-weighted covariance target without changing `akm/stylized`'s nine-row target contract. Only `theta_sort` is fitted, with fixed calibration and held-out seed ensembles; all hazards and duration coefficients remain explicit stylized carryovers.

Checkpoint 38 raises the internal Mata API to version 26 and the shared population schema to version 4. `src/fesim_paygap.mata` and `src/fesim_paygap_handler.mata` open the public `akmpaygap/simple` and `akmpaygap/cck2016` routes. The handler streams full internal truth so the postprocessor can recompute group moments and three exact decompositions after optional largest-component filtering, then prunes output truth to the requested level. Ten group/type destination tables avoid worker-by-firm matrices. The common finalizer returns group target and decomposition matrices plus the D-034 coding, direction, and normalization metadata.

Checkpoint 39 changes no runtime source or public availability. D-036 freezes the planned `bm/simple` route as the homogeneous-worker, common-productivity permanent-wage-posting equilibrium with distinct offer rates, an endogenous reservation wage, and steady-state flow-profit maximization. [`docs/bm_equilibrium.md`](bm_equilibrium.md) records the exact analytical solution, structural-level to public-log-wage mapping, existence conditions, and finite-firm boundary. `tests/unit/test_bm_derivation.do` independently checks the closed form against numerical quadrature and bisection plus equilibrium, stationary-distribution, and limiting identities. The BM route remains discovery-only pending its solver and simulation checkpoints.

Checkpoint 40 raises the internal Mata API to version 27 and adds the version-1 `fesim_bm_solution` container plus `src/fesim_bm.mata`. The continuum solver evaluates D-036 analytically, uses cancellation-safe small-rate series, checks the reservation condition through independently coded Simpson quadrature, and returns support-grid CDF, firm-size, profit, theoretical-flow, and scaled residual diagnostics. Invalid primitives and nonpositive public log-wage support fail before a solution is returned; analytical/numerical validation failures return a convergence error. The module is source-installed and loader-tested but consumes no RNG, touches no caller data, and does not open the discovery-only BM route. The installed loader now resolves its own Stata `f/` source sibling before any general `adopath` fallback, closing the stale-source precedence hole exposed by the API-27 source-only test.

Checkpoint 41 raises the internal Mata API to version 28 and adds the version-1 finite-firm BM container. Deterministic midpoint quantiles and isolated-stream random quantiles map through the analytical inverse offer CDF, receive wage-ranked stable IDs, and carry both continuum theory and exact finite stationary masses under uniform contacts and strict upward acceptance.

Checkpoint 42 raises the internal Mata API to version 29 and adds the version-1 BM event-history container. The exact continuous-time engine uses exponential waits, employed competing offer/destruction types, uniform contacted firms, strict upward acceptance, worker-local spells and durations, optional draw-equivalent event recording, and isolated event/contact streams.

Checkpoint 43 raises the internal Mata API to version 30 and adds the version-1 BM state container. It supports exact finite stationary starts with backward spell ages, a random diagnostic start requiring burn-in, a draw-free all-unemployed start, and unrecorded burn-in through the exact event engine with retained-boundary count reset.

Checkpoint 44 raises the internal Mata API to version 31 and adds the version-1 BM panel container. One recorded history replays into right-closed annual, quarterly, or monthly endpoints with exact interval event counts and exposure, established adjacent-endpoint flow semantics, and separately labeled theory, event-hazard, and observed-flow diagnostics.

Checkpoint 45 raises the internal Mata API to version 32 and adds `src/fesim_bm_output.mata` with BM-output schema 1. The private public-shaped writer preflights all arrays, maps structural accepted wages in levels to the common log-wage panel, converts public durations to output-period units, preserves first-row common transition missingness, and implements none/basic/full D-041 truth without drawing. Closed-form unemployment/employment values plus solver and finite-versus-continuum firm diagnostics remain separately named. The source-only loader and build cover the new module, but public BM dispatch stays closed.

Checkpoint 22 preserves the graph contract while replacing nonlinear interpreted aggregation and large membership-matrix transfers. The public route constructs compressed exact worker-firm keys, uses union by rank with deterministic lowest-worker component IDs, performs grouped native diagnostics, skips unused membership matrices under `connectivity(keep)`, and writes the retained-row marker directly under `connectivity(largest)`. Exact before/after and 10-million-row results are in [`docs/performance.md`](performance.md).

## Version source

`fesim_version_info.ado` is the runtime version source of truth. Package metadata, help headers, and documentation must agree with it; later static checks should enforce that agreement.

## Test isolation

`tests/run_all.do` redirects Stata `PERSONAL` and `PLUS` to ignored scratch directories, rebuilds the Mata library, installs the package from the repository manifest, and then runs source tests with the checkout prepended to the ado-path. This prevents a stale user installation from satisfying the tests.

## Canonical BM public integration (API 33)

`_fesim_bm.ado` provides a transaction around configuration, the pure Mata
handler, graph/sample diagnostics, and the common finalizer. The handler solves
once, initializes workers, performs unrecorded burn-in, then generates/replays
complete worker histories in bounded blocks. Persistent event/destination draw
buffers preserve the private monolithic history for every block size. The block
writer allocates the final Stata dataset once; it does not keep a second full
panel. Temporary interval-event/exposure columns allow common connectivity
filtering before BM sample rates are computed. All five are dropped on success.
Errors restore both the caller dataset and caller RNG. No persistent solver cache
is used; D-042 defines the future cache key and keeps solveonly/solution private.

## CPV public integration (API 35)

`src/fesim_cpv.mata` solves the finite grouped Bellman system in O(J) after
sorting and evaluates contracts through prefix sums. `src/fesim_cpv_simulate.mata`
generates exact stationary contract-tenure histories, burn-in, bounded worker
blocks and structural output. `_fesim_cpv.ado` supplies rollback, shared graph
filtering/moments/durations and CPV results. Existing engine algorithms and
RNG stream IDs are unchanged. The public API remains 1; CPV schema is 1.

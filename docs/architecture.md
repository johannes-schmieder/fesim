# Development architecture

The [public interface contract](interface.md), installed help, registry, and
model notes define behavior. The current ten presets use six simulation
engines: interval AKM, monthly AKM, two-group pay-gap, continuous-time BM,
CPV bargaining, and finite-type BLM. Public API is 1; Mata API is 37.

## Stata entry points and configuration

`fesim.ado` detects discovery subcommands, resolves models/presets, validates
configuration before mutation, and enforces caller-data safety.
`fesim_registry.ado` owns common and non-BLM scalar defaults, units, bounds,
applicability, calibration classes, and aliases. `fesim__blm_registry.ado`
adds BLM scalar/matrix schemas. `fesim__schema.ado` supplies observed/truth
inventories, initialization/network support, and scientific source scope.

`fesim_config.ado` merges defaults, common named options, and scalar overrides;
rejects duplicate, unknown, inapplicable, and inconsistent values; resolves time;
and returns canonical configuration/source metadata. Alias spelling does not
alter the canonical configuration. `fesim__blm_config.ado` additionally copies
and validates matrix inputs and recipe conflicts. Model overrides reclassify
presets; layout changes alone do not. See [calibration](calibration.md).

`fesim__load.ado` checks the Mata API and prefers source belonging to the installed
ado files, protecting against stale library/source precedence. Installed Mata
source is authoritative. `src/build_mlib.do` registers all source and builds a
development library in ignored `build/`; installation must work without it.
`fesim_version_info.ado` is the runtime version source. All installed basenames
start with `fesim`; internal ado helpers use `fesim__*`. In a checkout, the loader
reads `src/`; in a Stata installation, it reads adjacent Mata files before global
adopath lookup, so a shadow source cannot override the installed package.

## Shared infrastructure

| Source | Responsibility |
| --- | --- |
| `src/fesim_types.mata` | Versioned typed configuration, population, state, and result containers |
| `src/fesim_rng.mata` | Isolated component streams and caller-state discipline |
| `src/fesim_time.mata`, `src/fesim_hazards.mata` | Output time and annual probability/hazard conversions |
| `src/fesim_destinations.mata` | Weighted destinations with current-firm exclusion and grouped sampling |
| `src/fesim_network_design.mata` | Block, exact imposed-bridge, and reduced-form ladder designs |
| `src/fesim_lifecycle.mata`, `src/fesim_dispatch.mata` | Lifecycle validation and model dispatch |
| `src/fesim_output.mata`, `src/fesim_flows.mata` | Block output and observed flow finalization |
| `src/fesim_moments.mata`, `src/fesim_network.mata` | Common moments, bipartite/firm graphs, and leave-out audits |
| `src/fesim_runtime.mata` | Transactional ownership of available Stata timers |
| `fesim__finalize.ado` and common `fesim__*` postprocessors | Filtered-sample recomputation, metadata, returns, and reporting |

Keep the full final panel in Stata and write complete worker blocks directly.
Do not retain a second full Mata panel or a full-population event ledger.
Temporary memory and returned-data memory have distinct scaling. The private
deterministic toy handler is test infrastructure, never a registered public DGP.

## Scientific engines

**Simple AKM:** `src/fesim_akm_simple.mata` constructs permanent worker/firm
effects and attraction, exact interval stationary/random starts, competing
transitions, spells/durations, burn-in, and additive wages. The handler in
`src/fesim_akm_handler.mata` streams output and maintains truth moments even
when truth columns are suppressed. See [simple AKM](akm_simple.md).

**Monthly AKM:** `src/fesim_empirical.mata` constructs correlated mobility
indices, duration/type/quality-dependent hazards, grouped destinations, and
fixed-month histories. `src/fesim_emp_handler.mata` aggregates transitions
and converts durations to output units. See [stylized AKM](akm_stylized.md).

**Pay-gap:** `src/fesim_paygap.mata` and `src/fesim_paygap_handler.mata` generate
groups, common surplus, group premium schedules, and group mobility, retaining
exact additive decomposition under three references. See [pay-gap](akm_paygap.md).

**BM:** `src/fesim_bm.mata` solves the continuum equilibrium and constructs finite
firms. Event, initial, aggregate, output, and handler modules generate/replay
continuous worker histories in bounded blocks. Buffered event/destination draws
preserve paths across blocks. `fesim__bm.ado` owns rollback, graph/sample
postprocessing, and finite-versus-continuum diagnostics. There is no persistent
solution cache. See [BM](bm_equilibrium.md).

**CPV:** `src/fesim_cpv.mata` solves grouped finite-firm Bellman equations in O(J)
after sorting and evaluates contracts with prefix sums.
`src/fesim_cpv_simulate.mata` generates exact stationary contract-tenure histories,
continuous burn-in, bounded blocks, and structural truth. `fesim__cpv.ado` owns
rollback, common filtering/moments/durations, and CPV-specific results.
See [CPV](cpv-derivation.md).

**BLM:** `src/fesim_blm.mata` resolves actual-firm allocation and type/cell
matrices, probabilities, and earnings maps. `src/fesim_blm_simulate.mata` runs
monthly worker-major histories with bounded output blocks and cell moments.
`fesim__blm.ado` owns transactions, shared diagnostics, generated/returned cell
summaries, and complete model serialization. See [BLM](blm.md).

## Test and compatibility obligations

`tests/run_all.do` isolates `PERSONAL`/`PLUS`, rebuilds Mata, installs from the
manifest, and runs the complete registered source tests. Exact receipts must
bind to clean source and the full inventory. Independent scientific oracles,
statistical bounds, frozen fixtures, failure/caller-state checks, and executable
examples establish different properties; static CI cannot replace Stata tests.
See [CI](ci.md), [validation](validation.md), and [compatibility](compatibility.md).

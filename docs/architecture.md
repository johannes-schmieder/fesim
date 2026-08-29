# Development architecture

The normative architecture is in [`DESIGN.md`](../DESIGN.md). This note records only implementation details established by the current source.

## Checkpoint 2 boundaries

The public `fesim.ado` layer performs subcommand detection, discovery dispatch, and data-safety enforcement. It delegates DGP and preset resolution, defaults, overrides, and validation before it considers replacing loaded data.

`fesim_registry.ado` is the authoritative source for canonical DGP names, aliases, presets, calibration classifications, configuration availability, and the `akm/simple` scalar schema. Each scalar record supplies type, units, bounds, bound closure, applicability, default value and source, and allowed input routes. Planned presets remain discoverable but cannot be configured or simulated.

`fesim_config.ado` is the shared resolver. It merges package/preset defaults with named common options and `parameters()` values; rejects duplicate, unknown, inapplicable, or invalid inputs; applies cross-parameter checks; and returns both a stable text serialization and a parameter matrix. Alias spelling is deliberately excluded from the serialization, so `akmsimple` and `akm, preset(simple)` yield identical canonical configurations. Model-parameter changes reclassify the calibration as `stylized_modified`; sample-layout changes do not.

The resolver and discovery commands neither set a seed nor request random draws. No DGP simulation loop exists in ado or Mata. Valid simulation syntax exits with return code 498 after configuration validation and before data clearing or RNG use.

## Mata source and build

Mata source files under `src/` are authoritative. `src/build_mlib.do` compiles the current `fesim_*()` functions into an ignored development library at `build/lfesim.mlib`, clears Mata, reindexes libraries, and calls the compiled API as a load test.

The development library is not required by the Checkpoint 2 discovery/configuration commands and is not distributed by `fesim.pkg`. Its configuration structure reserves the common fields and parameter vector needed by later Mata dispatch, but no simulation lifecycle has been added. Whether future releases ship source, a compiled library, or both remains design gate DG-02; the checkpoint does not decide it accidentally.

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

## Version source

`fesim_version_info.ado` is the runtime version source of truth. Package metadata, help headers, and documentation must agree with it; later static checks should enforce that agreement.

## Test isolation

`tests/run_all.do` redirects Stata `PERSONAL` and `PLUS` to ignored scratch directories, rebuilds the Mata library, installs the package from the repository manifest, and then runs source tests with the checkout prepended to the ado-path. This prevents a stale user installation from satisfying the tests.

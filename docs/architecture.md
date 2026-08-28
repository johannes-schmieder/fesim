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

## Version source

`fesim_version_info.ado` is the runtime version source of truth. Package metadata, help headers, and documentation must agree with it; later static checks should enforce that agreement.

## Test isolation

`tests/run_all.do` redirects Stata `PERSONAL` and `PLUS` to ignored scratch directories, rebuilds the Mata library, installs the package from the repository manifest, and then runs source tests with the checkout prepended to the ado-path. This prevents a stale user installation from satisfying the tests.

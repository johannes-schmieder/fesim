# Development architecture

The normative architecture is in [`DESIGN.md`](../DESIGN.md). This note records only implementation details established by the current source.

## Checkpoint 1 boundaries

The public `fesim.ado` layer currently performs subcommand detection, discovery dispatch, simulation-option parsing, input validation, and data/RNG safety checks. Canonical DGP and alias metadata have one provisional source in `fesim_registry.ado`. Checkpoint 2 will turn that minimal registry into the shared configuration and parameter-registry layer used by simulation.

No DGP simulation loop exists in ado or Mata. Valid simulation syntax exits with return code 498 after validation and before data clearing or RNG use.

## Mata source and build

Mata source files under `src/` are authoritative. `src/build_mlib.do` compiles the current `fesim_*()` functions into an ignored development library at `build/lfesim.mlib`, clears Mata, reindexes libraries, and calls the compiled API as a load test.

The development library is not required by the Checkpoint 1 discovery commands and is not distributed by `fesim.pkg`. Whether future releases ship source, a compiled library, or both remains design gate DG-02; the checkpoint does not decide it accidentally.

## Version source

`fesim_version_info.ado` is the runtime version source of truth. Package metadata, help headers, and documentation must agree with it; later static checks should enforce that agreement.

## Test isolation

`tests/run_all.do` redirects Stata `PERSONAL` and `PLUS` to ignored scratch directories, rebuilds the Mata library, installs the package from the repository manifest, and then runs source tests with the checkout prepended to the ado-path. This prevents a stale user installation from satisfying the tests.

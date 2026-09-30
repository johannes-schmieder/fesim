# Public contract and compatibility

The current source is `1.2.0-rc.1`, with ten presets, public API 1, and internal
Mata API 37. The stable `v0.1.0` tag contains simple AKM only. Current licensed
qualification is Stata/MP 19 on macOS Apple Silicon; see [validation](validation.md).

## Accepted names and syntax

Canonical routes are `akm/simple`, `akm/stylized`,
`akm/germany_chk_2002_2009`, `akmpaygap/simple`, `akmpaygap/cck2016`, and
`bm/simple`, plus `cpv/simple`, `cpv/heterogeneous`, `blm/static`, and `blm/dynamic`. The only aliases are `akmsimple`, `akmempirical`, and `bmsimple`.
In particular, `akmempirical` means the stylized preset, not Germany.

Stata accepts these existing option minima; spelling options out is preferred:

| Full option | Minimum spelling |
|---|---|
| `preset()` | `pres()` |
| `workers()` | `work()` |
| `firms()` | `firm()` |
| `periods()` | `period()` |
| `frequency()` | `freq()` |
| `connectivity()` | `connect()` |
| `network()` | `netw()` |

The remaining simulation options use their full names: `dgp()`, `start()`,
`seed()`, `initial()`, `burnin()`, `jobrule()`, `truth()`, `parameters()`,
`report`, `noreport`, and `clear`. `norep` is not accepted. Defaults and bounds
come from `fesim describe`; abbreviations do not create parameter-name aliases.
Numeric common controls (`workers`, `firms`, `periods`, `burnin`) can also be
supplied through `parameters()`. Named common options are preferred. Supplying
the same control through both routes is an error, even if the values agree.

`jobrule(end)` is the only observation rule. `connectivity(keep|largest)` is
implemented; `connectivity(force)` is reserved and fails before changing data
or RNG. `solveonly`, `solution()`, alternative output datasets, an explicit
initial employment share, and heterogeneous BM are outside this candidate.
All four network designs apply to AKM; pay-gap, BM, CPV, and BLM accept only `random`.
Seven network scalar rows in the pay-gap parameter matrix are reserved schema
entries and do not enable these designs.

## Discovery and returned data

`fesim describe` retains its existing config and four-column parameter matrix.
It adds `r(observed_variables)`, `r(truth_basic_variables)`,
`r(truth_full_variables)`, `r(conditional_variables)`, `r(initial_modes)`,
`r(networks)`, `r(source_note)`, `r(target_scope)`, and `r(parameter_units)`.
Full-truth metadata lists additions beyond basic truth; conditional fields are
reported separately. Bounds, bound closure, and units are printed per scalar.
`source_note` describes scientific provenance. Simulation `r(reference)` keeps
its existing meaning as a decomposition reference, not a citation.

The common observed schema, storage types, labels, time formats, adjacent-state
flow definitions, truth suppression, dataset characteristics, and named result
matrices remain as documented in [results](results.md), [output](output.md),
and the [manual](fesim_manual.pdf). Graph diagnostics keep the `generated` and
`returned` columns; filtering retains complete histories. No change to latent
BM event counts or finite-versus-continuum interpretation is implied.

## Version policy

Within v1, compatible additions may add options, presets, discovery metadata,
or separately named results. Existing option meanings, defaults, variable
semantics, and matrix names/order are compatibility commitments. Removal or
semantic changes require a major version, explicit migration notes, and tests.
If deprecation becomes necessary, first document the replacement and warning in
a minor release and retain the old interface for the rest of that major series.
Numerical bug fixes must disclose affected quantities and whether seeded output
changes. Bitwise reproducibility is qualified for a fixed source, command, seed,
and Stata environment; it is not promised across software/platform changes.

BLM's nine matrix keys extend `parameters()` without changing scalar semantics.
The 16-by-4 numeric scalar table is retained; separately named resolved tables
and full serialized model values specify matrix-driven behavior. Existing
legacy economic defaults and simulation algorithms are preserved. Matrix
inputs, initialization, and truth semantics are documented in [BLM](blm.md).

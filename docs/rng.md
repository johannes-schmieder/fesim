# RNG implementation and reproducibility scope

The authoritative behavioral requirements are in [`DESIGN.md`](../DESIGN.md), Section 15. This note records the qualified implementation strategy selected by the RNG spike.

## Component streams

`fesim` uses Stata's `mt64s` generator and one fixed nonoverlapping stream per stochastic component:

| Stream | Component |
|---:|---|
| 101 | worker primitives |
| 102 | firm primitives |
| 103 | initial states |
| 104 | mobility events |
| 105 | destination draws |
| 106 | wage shocks |
| 107 | observation error |
| 108 | solver or calibration randomization |
| 109 | network design assignments and priorities |

Stata documents `mt64s` as 32,767 nonoverlapping streams of length 2^128 for a common seed. The manager captures each component's full RNG state, restores that state before a component draw, advances only that component, and then restores the caller's current generator and state. RNG states remain inside Mata; they are not expanded through Stata command text.

## Seed behavior

- With `seed(#)`, `#` is the component-stream master seed. The caller's current RNG generator and state are unchanged after initialization and component draws.
- Without `seed()`, `fesim` obtains one master seed by drawing a single integer in [0, 2^31-1] from the caller's current Stata RNG. It preserves the resulting continuation state, so the caller's RNG advances by exactly that one draw. Component simulation then uses the dedicated streams without further advancing the caller's sequence.
- No system clock, process ID, or foreign random-number implementation enters either route.

This protocol makes component draw order local: for example, adding observation-error or network-design draws does not change worker primitives, mobility events, destinations, or wage shocks. `network(random)` consumes no network-design draws; block assignments use stream 109 only.

## Qualified scope

The executable spike and deterministic manager tests currently qualify Stata/MP 19.0, revision 12 Aug 2026, on macOS Apple Silicon. Reproducibility means bitwise equality for a fixed `fesim` source/version, command, explicit seed, and qualified Stata environment. Cross-version or cross-platform bitwise equality is not claimed without matching receipts.

Discovery, configuration validation, deterministic output writing, and invalid commands consume no draws. DGP-level `report`/`noreport` and truth-mode invariance will be tested again once simulation output exists.

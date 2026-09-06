# `fesim` performance baselines

## Scope

The reproducible public benchmark runs `fesim, dgp(akm) preset(simple)` with
500 firms, 10 annual periods, seed 20260829, `truth(none)`,
`connectivity(keep)`, `noreport`, and `clear`. The benchmark records public
command time, internal simulation and output-stage time, dataset width, graph
scale, and macOS process-resource measurements.

The qualified environment is Stata/MP 19.0, 8-core, revision 12 Aug 2026, on
macOS Apple Silicon. The JSON, log, and `/usr/bin/time -l` receipts are ignored
local build artifacts under `build/benchmarks/<exact-sha>/`.

## Exact-source results

| SHA | Workers x periods | Rows | Command | Simulate | Output | Maximum RSS | Peak footprint |
|---|---:|---:|---:|---:|---:|---:|---:|
| `9e09109237c11baab9922e34d1579b644735718c` | 10,000 x 10 | 100,000 | 1.950 s | 1.041 s | 0.805 s | 116,998,144 B | 100,238,080 B |
| `56dcb363a1c0b7bd9bf32ea622cf807f9c59c4a2` | 10,000 x 10 | 100,000 | 1.623 s | 1.039 s | 0.481 s | 94,519,296 B | 78,348,984 B |
| `9e09109237c11baab9922e34d1579b644735718c` | 100,000 x 10 | 1,000,000 | 85.755 s | 7.930 s | 77.147 s | 465,666,048 B | 449,381,360 B |
| `56dcb363a1c0b7bd9bf32ea622cf807f9c59c4a2` | 100,000 x 10 | 1,000,000 | 13.210 s | 7.596 s | 5.032 s | 375,865,344 B | 359,859,112 B |
| `4b35c071eda405ced743db3fda56988313f21bdc` | 10,000 x 10 | 100,000 | 1.855 s | 1.173 s | 0.541 s | 225,312,768 B | 125,322,464 B |
| `4b35c071eda405ced743db3fda56988313f21bdc` | 100,000 x 10 | 1,000,000 | 15.016 s | 8.967 s | 5.390 s | 508,542,976 B | 408,634,736 B |
| `c73c6244227c3c949b3f06224f33b172e04b1c39` | 10,000 x 10 | 100,000 | 1.514 s | 0.837 s | 0.532 s | 221,003,776 B | 124,667,080 B |
| `67abdc4aa124ad2cfc11ea7ad76455e389706e8a` | 10,000 x 10 | 100,000 | 1.592 s | 0.869 s | 0.544 s | 221,609,984 B | 124,175,536 B |
| `67abdc4aa124ad2cfc11ea7ad76455e389706e8a` | 100,000 x 10 | 1,000,000 | 12.028 s | 5.805 s | 5.537 s | 515,735,552 B | 415,827,288 B |
| `56dcb363a1c0b7bd9bf32ea622cf807f9c59c4a2` | 1,000,000 x 10 | 10,000,000 | 148.416 s | 73.630 s | 68.321 s | 2,262,646,784 B | 2,247,887,080 B |

All datasets use 41 bytes per row. The optimized 10,000- and 100,000-worker
runs exactly match their respective before runs on retained rows, employed
observations, unique worker-firm edges, and component count. At 100,000
workers these values are 1,000,000 rows, 882,622 employed observations,
246,078 edges, and one component.

## Bottleneck and optimization

Before optimization, graph diagnostics dominated the output stage. At 100,000
workers the output stage used 77.147 of 85.077 internal seconds. Profiling
traced the nonlinear cost to transferring a worker-length component vector
through a Stata matrix, plus interpreted aggregation and validation loops.

The optimized route:

- forms exact worker-firm keys when their integer encoding is exactly
  representable, with a lexicographic pair-sort fallback outside that range;
- uses union by rank while normalizing component IDs to the lowest active
  worker ID;
- uses grouped native aggregation for component counts;
- avoids producing unused worker and firm membership matrices under
  `connectivity(keep)`; and
- writes the retained-row marker directly for `connectivity(largest)`.

At 100,000 workers, command time fell 84.6 percent and output-stage time fell
93.5 percent, while maximum RSS fell 19.3 percent. Simulation is now the
largest stage at 100,000 workers. At one million workers, simulation and output
are approximately balanced, so later optimization should profile the common
moment calculations and simulation engine before revisiting graph traversal.

Performance changes passed the frozen deterministic fixtures, statistical
tests, graph tie-breaking fixtures, source-only install test, and complete
exact-SHA Stata suite.

## Checkpoint 30 observed mobility summaries

Checkpoint 30 adds an undirected firm mobility graph after the established
bipartite component pass. The runtime validates the finalized `jobtojob`
indicators in Stata and transfers only observed mover origin-destination pairs
to Mata. It sorts unordered pairs, collapses distinct links, counts incident
firms, and computes link-weight percentiles. No dense firm-by-firm or projected
worker matrix is allocated.

The first exact implementation transferred four complete panel columns and
peaked at 579,715,072 bytes on the 1,000,000-row simple benchmark. The final
`4b35c071eda405ced743db3fda56988313f21bdc` mover-pair transfer reduced that
maximum by 12.3 percent to 508,542,976 bytes. It completed in 15.016 command
seconds, including 5.390 output seconds, with the same 882,622 employed
observations, 246,078 worker-firm edges, and one component as the earlier
baseline.

The closest same-route comparison is the 100,000-row stylized default. It took
4.458 command seconds versus 4.421 before the expanded graph, a 0.8 percent
increase, while maximum RSS changed from 232,554,496 to 231,243,776 bytes.
Its output stage rose from 0.508 to 0.549 seconds. The exact stylized JSON has
SHA256 `3f85518d2e86c38b5edabe3cfec985f754d1939efea8b9eda7f0bfc54bdea983`.

## Checkpoint 31 shared random destination primitive

Checkpoint 31 is a behavior-preserving extraction, not a new destination
design. At exact SHA `c73c6244227c3c949b3f06224f33b172e04b1c39`,
the 100,000-row simple route took 1.514 command seconds, including 0.837
simulation and 0.532 output seconds, with 221,003,776-byte maximum RSS. Its
JSON SHA256 is `5e4160b4148a61d0c052e1852316581f374d64f58e46fbbc179cfd1d823540c1`.

The corresponding stylized route took 4.460 command seconds, including 3.756
simulation and 0.551 output seconds, with 231,686,144-byte maximum RSS. Its
JSON SHA256 is `b2b5ce08ef911aea0f2a18b939400440e0af858b7244c1ab146c8f66ab6f6d38`.
After removing SHA and timing fields, both JSON results exactly match their
Checkpoint 30 controls. The simple timing improved in this single run, while
the stylized timing and both memory measurements stayed close to the prior
measurements; no structural speedup is claimed from one measurement.

## Checkpoint 34 articulation and graph-bridge diagnostics

Checkpoint 34 extends the same distinct undirected observed firm graph with a
memory-linear iterative depth-first traversal. At exact SHA
`67abdc4aa124ad2cfc11ea7ad76455e389706e8a`, the 100,000-row control took 1.592
command seconds, including 0.544 output seconds, with 221,609,984-byte maximum
RSS. Relative to the behavior-equivalent Checkpoint 31 route, output time was
0.012 seconds higher and maximum RSS was 0.3 percent higher. The JSON SHA256 is
`13aa70689e2801f7398e1a7e49f703b1c8ae1b978ffacd06c83d1005c84cf45d`.

The 1,000,000-row control took 12.028 command seconds, including 5.537 output
seconds, with 515,735,552-byte maximum RSS. Its JSON SHA256 is
`39817b0baa3c30299d85363d3f688644abe3eaa1488b87ab1847b76142e7d5a0`.
The closest retained large-scale observed-graph baseline used the same rows,
firms, seed, employed observations, and worker-firm edges; its output stage was
5.390 seconds and maximum RSS was 508,542,976 bytes. The 2.7 percent output-time
and 1.4 percent memory differences do not justify a separate public performance
switch at this scale. These are single-run complete-route comparisons, so no
causal overhead estimate is claimed.

## Checkpoint 35 reduced-form ladder destinations

Checkpoint 35 compares the frozen random destination rule with the default
reduced-form ladder at 10,000 workers, 500 firms, and 10 output periods for
both public AKM routes. The ladder implementation conditions an ordinary EE
probability vector over firms for each realized direct move; it constructs no
worker-by-firm matrix. The benchmark therefore measures the complete public
design rather than an isolated primitive.

Exact results at `e247f283bbc3f9c083a6dd54c529784819b7e4ec` are:

| Route/design | Rows | Command | Internal total | Simulate | Output | Components | Edges |
|---|---:|---:|---:|---:|---:|---:|---:|
| simple/random | 100,000 | 1.624 s | 1.445 s | 0.889 s | 0.556 s | 1 | 24,535 |
| simple/ladder | 100,000 | 5.078 s | 4.997 s | 4.452 s | 0.545 s | 2 | 24,552 |
| stylized/random | 100,000 | 4.498 s | 4.409 s | 3.842 s | 0.567 s | 2 | 21,928 |
| stylized/ladder | 100,000 | 12.321 s | 12.237 s | 11.649 s | 0.588 s | 2 | 21,713 |

The standards-compliant four-case JSON has SHA256
`00708aee34c0eb22d6ba20771442eb6dbc2176c07c9c04bb2dc7d6642763c280`.
The shared process reached 268,959,744 bytes maximum RSS and 165,627,080 bytes
peak memory footprint. Relative to random, internal total time was 3.46 times
as large for simple and 2.78 times as large for stylized; output time stayed
within 0.021 seconds, locating the measured cost in simulation as expected.
The component and edge counts are realized outcomes under
`connectivity(keep)`, not connectedness targets. These are single-run
complete-design comparisons, so they do not identify the marginal cost of one
EE redirection.

## Checkpoint 36 iterated leave-out diagnostics

Checkpoint 36 adds the `r(leaveout)` audit to the shared output stage. The
worker-history algorithm repeatedly finds articulation workers and retains the
deterministic largest remaining component until it is robust or empty. The
complete-match audit uses the same iterative depth-first traversal and counts
only bridge edges whose deletion separates firms. Both traversals use
adjacency lists; no dense worker-by-firm or firm-by-firm matrix is formed.

Exact results at `df8ef9d3afa7a9720b2cd61243ba270459481d1e` are:

| Route | Workers | Rows | Command | Internal total | Simulate | Output | Worker-set observation share | Base cut workers | Base vulnerable matches | Final vulnerable matches | Max RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| simple | 10,000 | 100,000 | 1.831 s | 1.634 s | 0.865 s | 0.769 s | 0.999808 | 2 | 3 | 0 | 226,820,096 B |
| simple | 100,000 | 1,000,000 | 13.353 s | 12.642 s | 5.829 s | 6.813 s | 1.000000 | 0 | 0 | 0 | 514,097,152 B |
| stylized | 10,000 | 100,000 | 4.792 s | 4.598 s | 3.830 s | 0.768 s | 0.999630 | 3 | 4 | 0 | 232,914,944 B |

Every final nonempty worker set is leave-one-worker robust by construction and
all three benchmark sets are also leave-one-match robust. At 10,000 workers,
the simple audit retains 9,998 workers, 497 firms, and 24,455 matches; the
stylized audit retains 9,991 workers, 496 firms, and 22,085 matches. At 100,000
workers, the simple largest component is already robust and the worker-set
observation share is one.

Relative to the Checkpoint 34 standard public controls, simple output time rose
from 0.544 to 0.769 seconds at 10,000 workers and from 5.537 to 6.813 seconds at
100,000 workers; total time rose by 15.6% and 11.5%, respectively. Maximum RSS
rose by 2.4% at 10,000 workers and fell by 0.3% at 100,000 workers. Relative to
the Checkpoint 30 stylized control, 10,000-worker output time rose from 0.549
to 0.768 seconds and total time rose by 6.8%, while maximum RSS rose by 0.7%.
These are single-run complete-command comparisons, not isolated causal timing
estimates.

The standards-compliant JSON SHA256 values are
`ce8c7cf17490737182f8dcfddabe2d073af6606fb7acd5afab1f06def5415827`
for the 10,000-worker simple result,
`d5cdda18250b4c84be41eea599c2438890b4d8346cacd6909036aed78bf9b9d2`
for the 100,000-worker simple result, and
`bb0814da2c3a1276a2f5cb3d5aa140d98111c20cdd46a9d2fb73661656644dca`
for the 10,000-worker stylized result. macOS Stata lingered only after writing
each PASS result; exact completed PIDs were terminated, so external wall times
include the post-PASS wait and are not reported as command runtimes.

## Checkpoint 37 targeted Germany preset

Checkpoint 37 adds the public `akm/germany_chk_2002_2009` preset. Its
interactive defaults use 10,000 workers, 1,000 firms, eight annual output
periods beginning in 2002, `truth(none)`, and `connectivity(keep)`. This
preserves the 10:1 worker-firm ratio used by the 100,000-worker calibration
design while keeping the public example practical.

The exact result at `1a1068b812f21356712842924d3ea1a89b6adc3b` is:

| Preset | Workers | Firms | Periods | Rows | Command | Internal total | Simulate | Output | Max RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Germany CHK | 10,000 | 1,000 | 8 | 80,000 | 4.255 s | 4.070 s | 3.332 s | 0.738 s | 231,456,768 B |

The result has 73,235 employed observations, 19,039 distinct worker-firm
edges, and 20 connected components. The iterated worker set retains 9,821
workers, 836 firms, and 18,707 matches; the final worker and match robustness
flags are both one. These are realized graph outcomes under
`connectivity(keep)`, not calibration targets.

The JSON artifact is
`build/benchmarks/1a1068b812f21356712842924d3ea1a89b6adc3b/germany-chk-10000x8-none.json`;
its SHA256 is
`517c7ce94306276e506525ab8cb1f53795a8f6bf9f643504cfe773a97eee6cff`.
The macOS Stata batch process lingered after writing the complete JSON and PASS
log. The exact completed PID was terminated after those artifacts were
verified, so the inflated external wall time is not a command-runtime measure.

## Reproducing

From a clean checkout:

```bash
scripts/run_public_benchmarks.sh /path/to/stata-mp
INCLUDE_MILLION=1 scripts/run_public_benchmarks.sh /path/to/stata-mp
scripts/run_stylized_benchmarks.sh /path/to/stata-mp
scripts/run_germany_chk_benchmark.sh /path/to/stata-mp
```

The second command repeats the two smaller controls before attempting the
million-worker run.

The Checkpoint 32 network-design harness runs 10,000-worker random and default
four-block controls for both public AKM presets in one exact-source process:

```bash
scripts/run_block_benchmarks.sh /path/to/stata-mp
```

It writes ignored JSON, log, and process-resource receipts under the same exact
SHA directory. The result records public command and internal stage times plus
the realized component and edge counts for each design.

Exact Checkpoint 32 results at
`b21917638cf83a2cef0d46e42f452585eaccc978` are:

| Route/design | Rows | Command | Internal total | Simulate | Output | Components | Edges |
|---|---:|---:|---:|---:|---:|---:|---:|
| simple/random | 100,000 | 1.605 s | 1.436 s | 0.899 s | 0.537 s | 1 | 24,535 |
| simple/blocks | 100,000 | 1.252 s | 1.175 s | 0.650 s | 0.525 s | 1 | 24,472 |
| stylized/random | 100,000 | 4.438 s | 4.356 s | 3.798 s | 0.558 s | 2 | 21,928 |
| stylized/blocks | 100,000 | 4.474 s | 4.393 s | 3.858 s | 0.535 s | 2 | 21,825 |

The four-case JSON SHA256 is
`5690a0a62155591dd5a9cce5110c3c004033367fc4853bab8e9b6a1d87b87967`.
The single process reached 255,066,112 bytes maximum RSS and 155,010,296 bytes
peak memory footprint. Those process-level values cover all four cases and are
not attributable to an individual row. The stylized comparison indicates
negligible block overhead at this scale. The faster simple block observation is
reported as a measurement only; no structural speedup is inferred from one run.

The Checkpoint 33 bridge harness uses the same 10,000-worker scale and compares
the default finite-bonus `network(blocks)` design with the strict-block
`network(bridges)` design for both public routes. The bridge cases use the
default four-block, three-bridge plan; their simulation time includes the
copied-state eligibility replay and the final economic run. Because the two
public designs also differ in their ordinary destination support, the timing
comparison measures the complete designs rather than identifying replay cost
alone. It can be reproduced from a clean checkout with:

```bash
scripts/run_bridge_benchmarks.sh /path/to/stata-mp
```

Exact Checkpoint 33 results at
`137755f04ac3c542b9303f4a162b524a73f44fdd` are:

| Route/design | Rows | Bridges | Command | Internal total | Simulate | Output | Components | Edges |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| simple/blocks | 100,000 | 0 | 1.393 s | 1.226 s | 0.686 s | 0.540 s | 1 | 24,472 |
| simple/bridges | 100,000 | 3 | 1.408 s | 1.333 s | 0.812 s | 0.521 s | 2 | 24,341 |
| stylized/blocks | 100,000 | 0 | 4.502 s | 4.421 s | 3.885 s | 0.536 s | 2 | 21,825 |
| stylized/bridges | 100,000 | 3 | 6.974 s | 6.891 s | 6.349 s | 0.542 s | 1 | 21,685 |

The four-case JSON SHA256 is
`5843ccad28ff399bcbb39587f682271dcdf8d2e6920246cec151a69b0ce016c6`.
The single process reached 256,868,352 bytes maximum RSS and 156,697,848 bytes
peak memory footprint. The simple bridge command was 1.1 percent slower than
the finite-bonus block control at this scale. The stylized bridge command was
54.9 percent slower, with the difference concentrated in simulation as
expected from replaying the monthly post-burn path. These are complete-design
comparisons from one run, not isolated causal estimates of replay overhead.

The Checkpoint 35 ladder harness compares random and ladder destinations at
10,000 workers, 500 firms, and 10 periods for both public routes:

```bash
scripts/run_ladder_benchmarks.sh /path/to/stata-mp
```

It emits a standards-compliant JSON result plus the Stata log and shared
process-resource receipt under the exact-SHA benchmark directory.

## Grouped empirical destination engine

Checkpoint 27 separately benchmarks construction and sampling for the D-025
destination kernel. Each exact-source run builds five worker-type UE tables,
five lower EE prefix tables, and five upper EE reverse-prefix tables, then
performs 100,000 deterministic UE draws and 100,000 deterministic EE draws.
The EE check verifies every destination differs from its current firm.

| SHA | Firms | Table payload | Build | UE draws | EE draws | Maximum RSS |
|---|---:|---:|---:|---:|---:|---:|
| `8986da475a762fe3a3c4be7d8a3e5560927b86ef` | 10,000 | 1,600,208 B | 0.005 s | 0.345 s | 0.402 s | 33,734,656 B |
| `8986da475a762fe3a3c4be7d8a3e5560927b86ef` | 100,000 | 16,000,208 B | 0.039 s | 1.292 s | 1.386 s | 59,031,552 B |
| `8986da475a762fe3a3c4be7d8a3e5560927b86ef` | 1,000,000 | 160,000,208 B | 0.379 s | 14.144 s | 13.850 s | 295,108,608 B |

The persistent numeric payload is linear in firms: five firm vectors, three
`5 x J` cumulative tables, four five-element scale vectors, and six scalars.
Sampling uses binary inverse CDF lookups, so work is proportional to draws
times `log(J)`, not workers times firms. No worker-by-firm matrix is created.
The benchmark environment and ignored-artifact policy are the same as above.

From a clean checkout, reproduce these results with:

```bash
scripts/run_destination_benchmarks.sh /path/to/stata-mp
INCLUDE_MILLION=1 scripts/run_destination_benchmarks.sh /path/to/stata-mp
```

## Canonical BM — Checkpoint 48 (2026-09-05)

Exact source: `38eb5bc4a0bc6ff8d19ec6e76679872e52e3519f` (`0.4.0-dev`, API 33); Stata/MP 19.0, eight cores,
macOS Apple Silicon. The same source passes the complete 60-file Stata suite.
Run `scripts/run_bm_benchmarks.sh` for the eight cases. All use 500 firms,
10 annual years, stationary initialization without burn-in, and seed 20260905.
Public cases include connectivity and leave-out diagnostics. Times below are
the public command's internal total, with solve/simulation/output sub-stages;
process startup is excluded. RSS is the separate process maximum from
`/usr/bin/time -l`, not just dataset or event-ledger payload.

| Worker-years | Truth | Total seconds | Simulation seconds | Output seconds | Max RSS bytes | Dataset bytes/row |
|---:|---|---:|---:|---:|---:|---:|
| 10,000 | full | 0.405 | 0.228 | 0.175 | 54,542,336 | 233 |
| 10,000 | none | 0.405 | 0.227 | 0.176 | 53,460,992 | 49 |
| 100,000 | full | 2.074 | 0.637 | 1.435 | 242,286,592 | 233 |
| 100,000 | none | 1.950 | 0.636 | 1.313 | 140,001,280 | 49 |
| 1,000,000 | full | 21.526 | 4.723 | 16.801 | 999,260,160 | 233 |
| 1,000,000 | none | 17.943 | 4.731 | 13.211 | 601,800,704 | 49 |

The million-row cases both generate 749,090 events; the largest retained
temporary block has 90,900 panel rows and 68,366 events. The full output dataset
and O(workers + firms) state still scale with the requested economy. Full truth
uses 233 bytes per output row versus 49 without truth. Output time includes
aggregation, block writes, sorting, graph/leave-out diagnostics, moments, and
metadata; it is not just disk or `st_store()` time.

The private unrecorded one-million-worker-year event run takes 2.416 seconds
and peaks at 45,613,056 bytes RSS, with a zero-byte event ledger. Recording the
same 749,090 events takes 4.101 seconds and yields a 65,919,920-byte ledger;
subsequent monolithic aggregation takes 4.823 seconds. That process peaks at
712,327,168 bytes because it includes the materialized million-row private
aggregation panel as well as the ledger and validation temporaries. This is a
private measurement of costs; public simulation uses bounded worker blocks.
Recorded/unrecorded runs agree on event totals, final employment (83,322), firm
ID sum (29,067,131), and transitions (458,082), supplementing the exact state
invariance unit tests. Public none/full runs also agree on event counts at every
sample size. Solver time is .001–.002 seconds, so solving fresh is preferable to
introducing cache state at this stage (D-042).

Ignored receipts/logs are under `build/benchmarks/<exact-sha>/`.

| JSON receipt | SHA-256 |
|---|---|
| `bm-100000x10-full.json` | `91df4f038a1182632b53dace08e82b393dbac97dbc39fa6d7282b8c229d793d4` |
| `bm-100000x10-none.json` | `28fb3636b057891ff9bf79cd8e7a80a90e0596de10e11b84dc8a6a1a301a7058` |
| `bm-10000x10-full.json` | `4358536836405d58bcf2ef748bd3fe293bc0da4f7d3154fa4523a15db4c2c347` |
| `bm-10000x10-none.json` | `dbffa7ba434784f925f53b7bf66e83f7abb7bb7e1c95d5a9da53b9eb37c79f14` |
| `bm-1000x10-full.json` | `4f70b0140b467717b2c0271bcc47d2b9d784551c224c7c136e5c94cd68f6ad16` |
| `bm-1000x10-none.json` | `79ca3340ed6fbb963b1c8610d167dd69109e456ccd459f196556215d69d961f5` |
| `bm-events-100000x10-record-0.json` | `45e54ea147f6f4fb8a2708d4f1debb514fb54eba46ff48e65895ba8a04d568fc` |
| `bm-events-100000x10-record-1.json` | `5ff701e064f37f979dd0ce3cb2e78b3fc12bb5f9b3e3e58f2042a8f42ebf6a04` |

## CPV candidate measurement protocol

Preserve the 26 existing controls with the unchanged release benchmark harness
and inputs, using pre-CPV source `1064f10c55ee4c3f7f0a74e3affa34cfa4a70148`
as baseline. Compare deterministic signatures/counts and measure runtime and
peak process RSS on the same macOS host. An increase above 10% triggers three
matched repeats; resolve a reproducible regression before accepting the candidate.

The separate `scripts/run_cpv_benchmarks.py` adds 20 cases: both presets at
1,000/10,000/100,000 workers over ten years with none/full truth; both presets
at 10,000 workers and 120 monthly snapshots with none/full truth; and a
heterogeneous full-truth firm-count sweep of 1/50/5,000/50,000 at 1,000 workers.
Each receipt binds source, harness, driver, dimensions, signature, event count,
stage timings and peak block rows. The common release harness is unchanged,
so all baseline and candidate legacy controls use identical tooling.

## CPV candidate qualification — 2026-09-06

Exact source `ab4de7140a66edc40f717395bfa4f5f2e061b3d5` passes all 20 CPV cases and the 26 legacy controls. The two first-pass time/RSS outliers do not reproduce above the 10% threshold in three paired repeats; all compared deterministic results match. See [the review report](qualification-1.1.0-rc.1.md) for the full initial/repeated legacy table, raw-artifact locations and hashes.

## CPV scaling results

All 20 cases pass at the exact candidate SHA. Annual cases cover ten years;
monthly cases cover the same ten years with 120 snapshots. Default stationary
initialization and seed 20260912 are fixed. Except for the final four firm-sweep
rows, firms number 500. Total time excludes Stata process startup and includes
solving, initial-state generation, simulation and common output diagnostics.
The exposed simulation stage includes initialization and snapshot construction;
output includes writing, graph/leave-out diagnostics, moments and metadata.

| Preset | Workers | Firms | Frequency | Truth | Rows | Total seconds | Solve seconds | Simulate seconds | Output seconds | Max RSS bytes | Peak block rows |
|---|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|
| simple | 1,000 | 500 | year | none | 10,000 | 0.365 | 0.002 | 0.063 | 0.300 | 52,838,400 | 10,000 |
| simple | 1,000 | 500 | year | full | 10,000 | 0.364 | 0.002 | 0.064 | 0.298 | 55,607,296 | 10,000 |
| simple | 10,000 | 500 | year | none | 100,000 | 1.594 | 0.002 | 0.616 | 0.976 | 128,335,872 | 100,000 |
| simple | 10,000 | 500 | year | full | 100,000 | 1.635 | 0.002 | 0.614 | 1.019 | 239,550,464 | 100,000 |
| simple | 100,000 | 500 | year | none | 1,000,000 | 13.837 | 0.002 | 6.138 | 7.697 | 536,510,464 | 100,000 |
| simple | 100,000 | 500 | year | full | 1,000,000 | 16.369 | 0.002 | 6.144 | 10.223 | 933,330,944 | 100,000 |
| simple | 10,000 | 500 | month | none | 1,200,000 | 10.760 | 0.003 | 3.804 | 6.953 | 570,802,176 | 99,960 |
| simple | 10,000 | 500 | month | full | 1,200,000 | 13.678 | 0.003 | 3.757 | 9.918 | 1,003,257,856 | 99,960 |
| heterogeneous | 1,000 | 500 | year | none | 10,000 | 0.361 | 0.003 | 0.063 | 0.295 | 54,149,120 | 10,000 |
| heterogeneous | 1,000 | 500 | year | full | 10,000 | 0.367 | 0.003 | 0.064 | 0.300 | 55,541,760 | 10,000 |
| heterogeneous | 10,000 | 500 | year | none | 100,000 | 1.549 | 0.002 | 0.614 | 0.933 | 126,812,160 | 100,000 |
| heterogeneous | 10,000 | 500 | year | full | 100,000 | 1.633 | 0.002 | 0.622 | 1.009 | 240,484,352 | 100,000 |
| heterogeneous | 100,000 | 500 | year | none | 1,000,000 | 13.593 | 0.002 | 6.159 | 7.432 | 543,244,288 | 100,000 |
| heterogeneous | 100,000 | 500 | year | full | 1,000,000 | 16.380 | 0.002 | 6.100 | 10.278 | 930,725,888 | 100,000 |
| heterogeneous | 10,000 | 500 | month | none | 1,200,000 | 10.685 | 0.003 | 3.865 | 6.817 | 566,181,888 | 99,960 |
| heterogeneous | 10,000 | 500 | month | full | 1,200,000 | 13.718 | 0.002 | 3.836 | 9.880 | 1,004,240,896 | 99,960 |
| heterogeneous | 1,000 | 1 | year | full | 10,000 | 0.324 | 0.000 | 0.060 | 0.264 | 54,411,264 | 10,000 |
| heterogeneous | 1,000 | 50 | year | full | 10,000 | 0.336 | 0.000 | 0.060 | 0.276 | 54,755,328 | 10,000 |
| heterogeneous | 1,000 | 5,000 | year | full | 10,000 | 0.361 | 0.024 | 0.062 | 0.275 | 55,099,392 | 10,000 |
| heterogeneous | 1,000 | 50,000 | year | full | 10,000 | 0.582 | 0.233 | 0.062 | 0.287 | 72,843,264 | 10,000 |

The million-row annual panels take 13.593–16.380 seconds and peak at
536,510,464–933,330,944 bytes RSS. Both presets/truth modes generate the same
499,495 primitive events. Monthly panels have 1.2 million rows and take
10.685–13.718 seconds; their 49,993 events equal the 10,000-worker annual
controls. Temporary panel blocks never exceed 100,000 rows (99,960 for monthly
output). The complete returned dataset and worker/firm state still scale with
the requested population; this is not a constant-total-memory claim. Dataset
width is 49 bytes without truth and 225 with full truth. At 50,000 firms the
solver takes .233 seconds and total time .582 seconds, with 72,843,264 bytes
process RSS. No cache or solve-only interface is justified by these measurements.

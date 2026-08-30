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

## Reproducing

From a clean checkout:

```bash
scripts/run_public_benchmarks.sh /path/to/stata-mp
INCLUDE_MILLION=1 scripts/run_public_benchmarks.sh /path/to/stata-mp
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

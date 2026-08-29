# Simple-AKM performance baseline

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

## Reproducing

From a clean checkout:

```bash
scripts/run_public_benchmarks.sh /path/to/stata-mp
INCLUDE_MILLION=1 scripts/run_public_benchmarks.sh /path/to/stata-mp
```

The second command repeats the two smaller controls before attempting the
million-worker run.

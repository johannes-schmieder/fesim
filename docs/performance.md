# Performance and memory

Measurements below are historical same-host benchmarks, not speed or memory
guarantees. They use Stata/MP 19 on macOS Apple Silicon. Runtime includes the
complete command and diagnostics; peak RSS is the external process maximum,
including Stata itself. RSS is not incremental dataset memory or PSS.

## Representative measured workloads

| Model/source | Workload | Command seconds | Peak process RSS |
| --- | --- | ---: | ---: |
| BM, `f936f0a` | 100,000 workers, 10 annual snapshots, none/full truth | 17.943–21.526 | 602–999 MB |
| CPV, `e90e4f4` | 100,000 workers, 500 firms, 10 annual snapshots, both presets and none/full truth | 13.593–16.380 | 537–933 MB |
| BLM, `03426c6` | 100,000 workers, 500 firms, 10 annual snapshots, both presets and none/full truth | 94.929–97.138 | 473–640 MB |

The source IDs refer to the cleaned history; their runtime contents match the
originally benchmarked revisions.

MB denotes decimal millions of bytes. BLM uses six worker types, ten firm
classes, and 20 years of burn-in; these cases include 36 million worker-months.
CPV uses exact stationary histories. Differences in economic work make these
rows unsuitable as a comparison of algorithmic efficiency across models.

Temporary panel blocks peak at 100,000 rows in the CPV/BLM workloads. The
returned Stata dataset and worker/firm state still grow with population and
horizon. Full truth widens each row; higher output frequency creates more rows.
Continuous-event budgets can reject a run before the panel reaches its row limit.

## Reproduce measurements

The portable benchmark harnesses under `scripts/` accept a licensed Stata
executable through `STATA_BIN` and write raw logs/receipts to ignored `build/`.
Use clean exact source and record source SHA, Stata version/revision/flavor,
OS/architecture, dimensions, initialization, burn-in, truth mode, command time,
stage time, event/work counts, and the external memory metric. See the full
[performance harness inventory](../tests/performance/README.md).

For regression comparisons, match baseline/candidate commands, seeds, and
host conditions; compare deterministic outputs before timing. Repeat outliers
in fresh paired runs with alternating order rather than treating one timing
as a stable regression. Historical BLM qualification matched all 46 legacy/CPV
deterministic controls and passed 20 BLM scale cases; three matched pairs per
initial outlier left no median time/RSS increase above 10%.
See [validation](validation.md) for source qualification boundaries.

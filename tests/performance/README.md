# Performance tests

`benchmark_public.do` exercises the public simple-AKM route with fixed seed,
500 firms, 10 periods, `truth(none)`, and `connectivity(keep)`. It writes a
standards-compliant JSON receipt containing the exact Git SHA, dataset scale,
graph scale, leave-out counts and robustness flags, command time, and internal
stage times. The harness rejects malformed JSON.

Run the clean-checkout harness with:

```bash
scripts/run_public_benchmarks.sh /path/to/stata-mp
```

Set `INCLUDE_MILLION=1` to repeat the standard 10,000- and 100,000-worker
controls and then attempt 1,000,000 workers. The harness also records
`/usr/bin/time -l` output for process resource use. Results live in ignored
`build/benchmarks/<exact-sha>/` directories. See `docs/performance.md` for the
qualified baseline and before/after interpretation.

`benchmark_destinations.do` isolates the grouped empirical destination engine.
`benchmark_stylized_public.do` measures the public monthly empirical-mobility
route, including five years of burn-in, monthly-to-output aggregation, duration
returns, graph and leave-out diagnostics, and the final Stata dataset. Its
harness also rejects malformed JSON. The same benchmark accepts the distinct
Germany preset when requested; `scripts/run_germany_chk_benchmark.sh` fixes its
interactive defaults at 10,000 workers, 1,000 firms, and eight periods.
It times construction of the five worker-type UE and EE tables and 100,000
draws from each kernel, verifies exact current-firm exclusion, and records the
numeric payload of the persistent tables. Run it from a clean checkout with:

```bash
scripts/run_destination_benchmarks.sh /path/to/stata-mp
```

The standard firm counts are 10,000 and 100,000. Set `INCLUDE_MILLION=1` for
the optional one-million-firm table and `DESTINATION_DRAWS=<N>` to change the
number of draws per kernel. The implementation stores three `5 x J` cumulative
tables and five `J x 1` firm vectors; it never constructs a worker-by-firm
matrix.

`benchmark_network_blocks.do` compares the common random and default
finite-bonus block designs. `benchmark_network_bridges.do` compares that public
block design with the strict-block bridge design for both public routes and
records the exact number of imposed bridges. `benchmark_network_ladder.do`
compares random and default reduced-form ladder destinations in both public
routes. Run their clean-checkout harnesses
with:

```bash
scripts/run_block_benchmarks.sh /path/to/stata-mp
scripts/run_bridge_benchmarks.sh /path/to/stata-mp
scripts/run_ladder_benchmarks.sh /path/to/stata-mp
```

## Canonical BM

Run `scripts/run_bm_benchmarks.sh` with a licensed Stata executable from a clean
checkout. Six public cases cover 10,000/100,000/1,000,000 worker-years under
none/full truth with 500 firms. Two private cases measure unrecorded versus
recorded events at 100,000 workers over 10 years; recorded history is also
aggregated separately. JSON, Stata logs, and macOS process-resource receipts
are saved under the exact source SHA in ignored `build/benchmarks/`. Runtime
receipts carry the clean SHA; the wrapper rejects changes during measurement.

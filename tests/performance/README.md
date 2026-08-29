# Performance tests

`benchmark_public.do` exercises the public simple-AKM route with fixed seed,
500 firms, 10 periods, `truth(none)`, and `connectivity(keep)`. It writes a
machine-readable JSON receipt containing the exact Git SHA, dataset scale,
graph scale, command time, and internal stage times.

Run the clean-checkout harness with:

```bash
scripts/run_public_benchmarks.sh /path/to/stata-mp
```

Set `INCLUDE_MILLION=1` to repeat the standard 10,000- and 100,000-worker
controls and then attempt 1,000,000 workers. The harness also records
`/usr/bin/time -l` output for process resource use. Results live in ignored
`build/benchmarks/<exact-sha>/` directories. See `docs/performance.md` for the
qualified baseline and before/after interpretation.

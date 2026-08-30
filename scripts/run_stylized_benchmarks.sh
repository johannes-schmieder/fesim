#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stata_binary=${STATA_BIN:-${1:-}}
include_large=${INCLUDE_LARGE:-0}

if [[ -z "$stata_binary" || ! -x "$stata_binary" ]]; then
    echo "Set STATA_BIN or pass the licensed Stata executable as argument 1." >&2
    exit 2
fi

dirty=$(git -C "$repository_root" status --porcelain --untracked-files=all)
if [[ -n "$dirty" ]]; then
    echo "Refusing performance evidence from a dirty checkout:" >&2
    echo "$dirty" >&2
    exit 2
fi

source_sha=$(git -C "$repository_root" rev-parse HEAD)
output_dir="$repository_root/build/benchmarks/$source_sha"
mkdir -p "$output_dir"
sizes=(10000)
if [[ "$include_large" == "1" ]]; then
    sizes+=(100000)
fi

for workers in "${sizes[@]}"; do
    stem="stylized-${workers}x10-none"
    result="$output_dir/$stem.json"
    timing="$output_dir/$stem.time.txt"
    log="$output_dir/$stem.log"
    (
        cd "$output_dir"
        /usr/bin/time -l "$stata_binary" -q -b do \
            "$repository_root/tests/performance/benchmark_stylized_public.do" \
            "$repository_root" "$source_sha" "$workers" 500 10 none \
            "$result"
    ) >"$log" 2>"$timing"
    if [[ ! -s "$result" ]]; then
        echo "Benchmark did not create $result" >&2
        exit 1
    fi
    python3 -m json.tool "$result" >/dev/null
    echo "FESIM STYLIZED BENCHMARK ACCEPTED: $result"
done

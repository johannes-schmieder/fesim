#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stata_binary=${STATA_BIN:-${1:-}}
destination_draws=${DESTINATION_DRAWS:-100000}
include_million=${INCLUDE_MILLION:-0}

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
sizes=(10000 100000)
if [[ "$include_million" == "1" ]]; then
    sizes+=(1000000)
fi

for firms in "${sizes[@]}"; do
    stem="destinations-${firms}x${destination_draws}"
    result="$output_dir/$stem.json"
    timing="$output_dir/$stem.time.txt"
    log="$output_dir/$stem.log"
    (
        cd "$output_dir"
        /usr/bin/time -l "$stata_binary" -q -b do \
            "$repository_root/tests/performance/benchmark_destinations.do" \
            "$repository_root" "$source_sha" "$firms" \
            "$destination_draws" "$result"
    ) >"$log" 2>"$timing"
    if [[ ! -s "$result" ]]; then
        echo "Destination benchmark did not create $result" >&2
        exit 1
    fi
    echo "FESIM DESTINATION BENCHMARK ACCEPTED: $result"
done

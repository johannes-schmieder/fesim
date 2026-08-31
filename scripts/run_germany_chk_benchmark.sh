#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stata_binary=${STATA_BIN:-${1:-}}

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
stem="germany-chk-10000x8-none"
result="$output_dir/$stem.json"
timing="$output_dir/$stem.time.txt"
log="$output_dir/$stem.log"
(
    cd "$output_dir"
    /usr/bin/time -l "$stata_binary" -q -b do \
        "$repository_root/tests/performance/benchmark_stylized_public.do" \
        "$repository_root" "$source_sha" 10000 1000 8 none \
        "$result" germany_chk_2002_2009
) >"$log" 2>"$timing"

if [[ ! -s "$result" ]]; then
    echo "Benchmark did not create $result" >&2
    exit 1
fi
python3 -m json.tool "$result" >/dev/null
echo "FESIM GERMANY CHK BENCHMARK ACCEPTED: $result"

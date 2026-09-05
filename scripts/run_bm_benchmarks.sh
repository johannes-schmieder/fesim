#!/usr/bin/env bash
set -euo pipefail
repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stata_binary=${STATA_BIN:-${1:-}}
if [[ -z "$stata_binary" || ! -x "$stata_binary" ]]; then
    echo "Pass the licensed Stata executable or set STATA_BIN." >&2
    exit 2
fi
if [[ -n "$(git -C "$repository_root" status --porcelain --untracked-files=all)" ]]; then
    echo "Refusing BM performance evidence from a dirty checkout." >&2
    exit 2
fi
source_sha=$(git -C "$repository_root" rev-parse HEAD)
output_dir="$repository_root/build/benchmarks/$source_sha"
mkdir -p "$output_dir"
for workers in 1000 10000 100000; do
    for truth in none full; do
        stem="bm-${workers}x10-${truth}"
        result="$output_dir/$stem.json"
        rm -f "$result"
        (
            cd "$output_dir"
            /usr/bin/time -l "$stata_binary" -q -b do \
                "$repository_root/tests/performance/benchmark_bm.do" \
                "$repository_root" "$source_sha" "$workers" "$truth" "$result"
            mv benchmark_bm.log "$stem.log"
        ) >"$output_dir/$stem.stdout.txt" 2>"$output_dir/$stem.time.txt"
        python3 - "$result" "$source_sha" <<'PY'
import json, sys
from pathlib import Path
receipt = json.loads(Path(sys.argv[1]).read_text())
assert receipt['sha'] == sys.argv[2] and receipt['status'] == 'passed'
assert receipt['worker_years'] == receipt['workers'] * 10
print(f"FESIM BM BENCHMARK ACCEPTED: {sys.argv[1]}")
PY
    done
done
if [[ "$(git -C "$repository_root" rev-parse HEAD)" != "$source_sha" || -n "$(git -C "$repository_root" status --porcelain --untracked-files=all)" ]]; then
    echo "Source changed during BM performance measurement." >&2
    exit 2
fi

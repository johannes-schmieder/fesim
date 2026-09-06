#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stata_binary=${STATA_BIN:-${1:-}}
suite=${2:-quick}

if [[ -z "$stata_binary" || ! -x "$stata_binary" ]]; then
    echo "Set STATA_BIN or pass the licensed Stata executable as argument 1." >&2
    exit 2
fi

dirty=$(git -C "$repository_root" status --porcelain --untracked-files=all)
if [[ -n "$dirty" ]]; then
    echo "Refusing exact-source qualification from a dirty checkout:" >&2
    echo "$dirty" >&2
    exit 2
fi

source_sha=$(git -C "$repository_root" rev-parse HEAD)
branch=$(git -C "$repository_root" symbolic-ref --quiet --short HEAD || true)
if [[ -z "$branch" ]]; then
    branch=detached
fi

cd "$repository_root"
receipt="$repository_root/build/test-results/receipt-$source_sha.json"
# Batch Stata can return OS status zero after a do-file error. A stale receipt
# must never turn such a failed rerun into accepted evidence.
rm -f "$receipt"
"$stata_binary" -q -b do tests/run_all.do \
    "$repository_root" "$source_sha" "$suite" "$branch"

python3 "$repository_root/scripts/verify_stata_receipt.py" \
    "$receipt" "$source_sha"

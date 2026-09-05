#!/usr/bin/env bash
set -euo pipefail
repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$repository_root/build/manual"
cd "$repository_root/docs"
latexmk -pdf -interaction=nonstopmode -halt-on-error \
    -outdir=../build/manual fesim_manual.tex
cp ../build/manual/fesim_manual.pdf fesim_manual.pdf

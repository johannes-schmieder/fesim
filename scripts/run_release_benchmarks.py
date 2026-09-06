#!/usr/bin/env python3
"""Run matched macOS candidate controls against a clean source checkout."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def run(root, stata, output, repetitions):
    root = root.resolve()
    if git(root, "status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Benchmark source must be clean.")
    sha = git(root, "rev-parse", "HEAD")
    output.mkdir(parents=True, exist_ok=True)
    cases = []
    for family, preset in [("akm", "simple"), ("akm", "stylized"),
                           ("akm", "germany_chk_2002_2009"),
                           ("akmpaygap", "simple"), ("akmpaygap", "cck2016"),
                           ("bm", "simple")]:
        for truth in ("none", "full"):
            cases.append((f"{family}-{preset}-{truth}",
                          Path(__file__).resolve().parents[1] / "tests/performance/benchmark_release.do",
                          [family, preset, "random", truth]))
    for preset in ("simple", "stylized"):
        for network in ("blocks", "bridges", "ladder"):
            cases.append((f"akm-{preset}-{network}",
                          Path(__file__).resolve().parents[1] / "tests/performance/benchmark_release.do",
                          ["akm", preset, network, "none"]))
    # Existing BM scale and private-ledger controls retain their original inputs.
    for workers in (1000, 10000, 100000):
        for truth in ("none", "full"):
            cases.append((f"bm-scale-{workers}-{truth}",
                          root / "tests/performance/benchmark_bm.do", [str(workers), truth]))
    for record in (0, 1):
        cases.append((f"bm-events-{record}",
                      root / "tests/performance/benchmark_bm_events.do",
                      ["100000", str(record)]))
    records = []
    for repetition in range(1, repetitions + 1):
        for name, driver, options in cases:
            stem = output / f"{name}-{repetition}"
            receipt = stem.with_suffix(".json")
            receipt.unlink(missing_ok=True)
            command = ["/usr/bin/time", "-l", str(stata), "-q", "-b", "do",
                       str(driver), str(root), sha, *options, str(receipt)]
            with stem.with_suffix(".stdout.txt").open("w") as out, stem.with_suffix(".time.txt").open("w") as err:
                subprocess.run(command, cwd=output, stdout=out, stderr=err, check=True)
            data = json.loads(receipt.read_text())
            if data.get("sha") != sha or data.get("status") != "passed":
                raise SystemExit(f"Invalid result: {receipt}")
            timing = stem.with_suffix(".time.txt").read_text()
            rss = re.search(r"(\d+)\s+maximum resident set size", timing)
            if not rss:
                raise SystemExit(f"Missing peak RSS: {stem}")
            records.append({"case": name, "repetition": repetition,
                            "peak_rss_bytes": int(rss[1]), "result": data})
            print(f"PASS {name} repetition {repetition}", flush=True)
    if git(root, "rev-parse", "HEAD") != sha or git(root, "status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Source changed during measurement.")
    summary = {"sha": sha, "harness_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
               "driver_sha256": hashlib.sha256((Path(__file__).resolve().parents[1] /
                   "tests/performance/benchmark_release.do").read_bytes()).hexdigest(),
               "status": "passed", "records": records}
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("stata", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--repetitions", type=int, default=1)
    args = parser.parse_args()
    if args.repetitions < 1:
        parser.error("repetitions must be positive")
    run(args.root, args.stata.resolve(), args.output.resolve(), args.repetitions)

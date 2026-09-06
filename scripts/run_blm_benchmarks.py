#!/usr/bin/env python3
"""Measure BLM worker, firm, truth and observation-frequency scaling on macOS."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def run(root, stata, output, repetitions):
    root, output = root.resolve(), output.resolve()
    if git(root, "status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Benchmark source must be clean.")
    sha = git(root, "rev-parse", "HEAD")
    driver = root / "tests/performance/benchmark_blm.do"
    output.mkdir(parents=True, exist_ok=True)
    cases = []
    for preset in ("static", "dynamic"):
        for workers in (1000, 10000, 100000):
            for truth in ("none", "full"):
                cases.append((preset, workers, 500, "year", truth, 6, 10))
        for truth in ("none", "full"):
            cases.append((preset, 10000, 500, "month", truth, 6, 10))
    for worker_types, firm_types in ((1, 1), (3, 5), (10, 10), (20, 20)):
        cases.append(("dynamic", 1000, 500, "year", "full", worker_types, firm_types))
    records = []
    for repetition in range(1, repetitions + 1):
        for preset, workers, firms, frequency, truth, worker_types, firm_types in cases:
            name = f"blm-{preset}-{workers}-{firms}-{frequency}-{truth}-{worker_types}x{firm_types}"
            stem = output / f"{name}-{repetition}"
            receipt = stem.with_suffix(".json")
            receipt.unlink(missing_ok=True)
            command = ["/usr/bin/time", "-l", str(stata), "-q", "-b", "do",
                       str(driver), str(root), sha, preset, str(workers), str(firms),
                       frequency, truth, str(worker_types), str(firm_types), str(receipt)]
            with stem.with_suffix(".stdout.txt").open("w") as out, stem.with_suffix(".time.txt").open("w") as err:
                subprocess.run(command, cwd=output, stdout=out, stderr=err, check=True)
            data = json.loads(receipt.read_text())
            if data.get("sha") != sha or data.get("status") != "passed":
                raise SystemExit(f"Invalid BLM receipt: {receipt}")
            rss = re.search(r"(\d+)\s+maximum resident set size", stem.with_suffix(".time.txt").read_text())
            if not rss:
                raise SystemExit(f"Missing peak RSS: {stem}")
            records.append({"case": name, "repetition": repetition,
                            "peak_rss_bytes": int(rss[1]), "result": data})
            print(f"PASS {name} repetition {repetition}", flush=True)
    if git(root, "rev-parse", "HEAD") != sha or git(root, "status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Source changed during measurement.")
    summary = {"sha": sha, "status": "passed", "records": records,
               "harness_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
               "driver_sha256": hashlib.sha256(driver.read_bytes()).hexdigest()}
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
    run(args.root, args.stata.resolve(), args.output, args.repetitions)

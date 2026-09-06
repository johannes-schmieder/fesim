#!/usr/bin/env python3
"""Build and qualify an unpublished source archive from exact clean HEAD."""
import argparse
import hashlib
import json
import subprocess
import tarfile
from pathlib import Path

from verify_stata_receipt import git, registered_tests, require


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(root, stata, output):
    root, output = root.resolve(), output.resolve()
    require(not git(root, "status", "--porcelain", "--untracked-files=all"), "source is dirty")
    sha = git(root, "rev-parse", "HEAD")
    require(not output.exists(), "use a new output directory for each archive qualification")
    output.mkdir(parents=True)
    archive = output / f"fesim-{sha}.tar.gz"
    subprocess.run(["git", "-C", str(root), "archive", "--format=tar.gz",
                    f"--output={archive}", sha], check=True)
    extracted = output / "source"
    extracted.mkdir()
    with tarfile.open(archive) as tar:
        for member in tar.getmembers():
            require(not member.issym() and not member.islnk(), "archive contains links")
            require(extracted in (extracted / member.name).resolve().parents,
                    "archive member escapes extraction directory")
        tar.extractall(extracted)
    files = [p for p in extracted.rglob("*") if p.is_file()]
    before = {str(p.relative_to(extracted)): digest(p) for p in files}
    forbidden = {".mlib", ".log", ".dta", ".gph", ".smcl"}
    require(not any(p.suffix in forbidden for p in files), "generated artifacts in archive")
    tests = registered_tests(extracted)
    # The extraction has no .git. This outer receipt binds the archive hash to
    # HEAD; do not pretend the checkout-only receipt verifier verified it.
    subprocess.run([str(stata), "-q", "-b", "do", "tests/run_all.do",
                    str(extracted), sha, "full", "archive"], cwd=extracted, check=True)
    receipt = extracted / f"build/test-results/receipt-{sha}.json"
    data = json.loads(receipt.read_text())
    require(data.get("status") == "accepted" and data.get("tests_failed") == 0,
            "archive suite failed")
    require(data.get("sha") == sha and data.get("repository") == str(extracted),
            "archive receipt has wrong provenance")
    require(data.get("tests") == tests and data.get("tests_passed") == len(tests),
            "archive did not run the registered inventory")
    for test in tests:
        log = extracted / f"build/test-results/{test.replace('/', '_')}.log"
        require(f"===== {test} rc=0 =====" in log.read_text(), f"missing success: {test}")
    require("FESIM CLEAN INSTALL SMOKE PASS" in
            (extracted / "build/test-results/install_smoke.log").read_text(),
            "isolated six-preset installation failed")
    require(before == {str(p.relative_to(extracted)): digest(p) for p in files},
            "tracked archive source changed during testing")
    require(git(root, "rev-parse", "HEAD") == sha and
            not git(root, "status", "--porcelain", "--untracked-files=all"),
            "source checkout changed during qualification")
    result = {"source_sha": sha, "archive_sha256": digest(archive),
              "suite_receipt_sha256": digest(receipt), "status": "accepted",
              "tests_passed": len(tests), "installed_presets": 6,
              "source_files": before, "platform": {key: data[key] for key in
                 ("stata_version", "stata_flavor", "os", "architecture")}}
    (output / "archive-receipt.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"FESIM EXACT ARCHIVE ACCEPTED {sha}: {len(tests)} test files, six presets")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("stata", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    run(args.root, args.stata.resolve(), args.output)

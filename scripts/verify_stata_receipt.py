#!/usr/bin/env python3
"""Verify that an accepted Stata receipt belongs to the exact clean checkout."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


class ReceiptError(RuntimeError):
    pass


def git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        check=check,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def repository_root(cwd: Path) -> Path:
    return Path(git(cwd, "rev-parse", "--show-toplevel")).resolve()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReceiptError(message)


def load_receipt(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReceiptError(f"cannot read receipt: {error}") from error
    require(isinstance(data, dict), "receipt must be a JSON object")
    return data


def verify(receipt_path: Path, expected_sha: str | None = None) -> str:
    root = repository_root(Path.cwd())
    head = git(root, "rev-parse", "HEAD").lower()
    require(SHA_PATTERN.fullmatch(head) is not None, "Git HEAD is not an exact SHA")
    if expected_sha is not None:
        expected_sha = expected_sha.lower()
        require(
            SHA_PATTERN.fullmatch(expected_sha) is not None,
            "expected SHA must be 40 lowercase hexadecimal characters",
        )
        require(expected_sha == head, "expected SHA does not equal checked-out HEAD")

    dirty = git(root, "status", "--porcelain", "--untracked-files=all")
    require(not dirty, "checkout has tracked or untracked source changes")

    receipt_path = receipt_path.resolve()
    data = load_receipt(receipt_path)
    receipt_sha = str(data.get("sha", "")).lower()
    require(SHA_PATTERN.fullmatch(receipt_sha) is not None, "receipt SHA is invalid")
    require(receipt_sha == head, "receipt SHA does not equal checked-out HEAD")
    require(
        receipt_path.name == f"receipt-{receipt_sha}.json",
        "receipt filename does not encode its SHA",
    )
    require(
        Path(str(data.get("repository", ""))).resolve() == root,
        "receipt repository does not equal the checked-out repository",
    )

    branch = git(root, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    if branch:
        require(data.get("branch") == branch, "receipt branch does not equal checkout")

    require(data.get("status") == "accepted", "receipt status is not accepted")
    require(data.get("exit_code") == 0, "receipt exit code is not zero")
    require(data.get("tests_failed") == 0, "receipt reports failed tests")
    require(
        isinstance(data.get("tests_passed"), int) and data["tests_passed"] > 0,
        "receipt has no positive test count",
    )
    require(data.get("mlib_rebuilt") is True, "receipt did not rebuild Mata source")
    for key in ("suite", "stata_version", "stata_flavor", "os", "architecture"):
        require(str(data.get(key, "")).strip() != "", f"receipt omits {key}")
    return receipt_sha


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path)
    parser.add_argument("expected_sha", nargs="?")
    args = parser.parse_args()
    try:
        sha = verify(args.receipt, args.expected_sha)
    except (ReceiptError, subprocess.CalledProcessError) as error:
        print(f"STATA RECEIPT REJECTED: {error}", file=sys.stderr)
        return 1
    print(f"STATA RECEIPT ACCEPTED FOR EXACT CLEAN HEAD {sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

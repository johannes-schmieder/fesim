#!/usr/bin/env python3
"""Dependency-free repository contract checks for GitHub-hosted CI."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CheckFailure(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CheckFailure(message)


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *args],
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout


def tracked_files() -> set[str]:
    return {name for name in git("ls-files").splitlines() if name}


def check_whitespace() -> None:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--check", "HEAD"],
        text=True,
        capture_output=True,
    )
    require(result.returncode == 0, result.stdout + result.stderr)


def check_no_tracked_artifacts(tracked: set[str]) -> None:
    forbidden_suffixes = {
        ".dta",
        ".gph",
        ".log",
        ".mlib",
        ".smcl",
        ".ster",
        ".stswp",
    }
    bad = sorted(
        name
        for name in tracked
        if name == ".DS_Store"
        or name.startswith("build/")
        or Path(name).suffix.lower() in forbidden_suffixes
    )
    require(not bad, "tracked generated/local artifacts: " + ", ".join(bad))


def check_package_manifest() -> None:
    manifest = (ROOT / "fesim.pkg").read_text(encoding="utf-8")
    entries = [
        line.split(maxsplit=1)[1].strip()
        for line in manifest.splitlines()
        if line.startswith("f ")
    ]
    require(entries, "fesim.pkg contains no installable files")
    require(len(entries) == len(set(entries)), "fesim.pkg repeats a file")
    for entry in entries:
        require((ROOT / entry).is_file(), f"manifest file does not exist: {entry}")
        require(
            Path(entry).suffix in {".ado", ".sthlp", ".mata"},
            f"unsupported installed runtime file: {entry}",
        )

    runtime_files = {
        path.name for suffix in ("*.ado", "*.sthlp") for path in ROOT.glob(suffix)
    }
    mata_sources = {
        str(path.relative_to(ROOT)) for path in (ROOT / "src").glob("fesim_*.mata")
    }
    expected_files = runtime_files | mata_sources
    require(
        set(entries) == expected_files,
        "fesim.pkg/runtime mismatch: "
        f"missing={sorted(expected_files - set(entries))}, "
        f"extra={sorted(set(entries) - expected_files)}",
    )
    require(
        re.search(r"^d Requires: Stata 19 or later;", manifest, re.MULTILINE)
        is not None,
        "fesim.pkg support floor is missing or inconsistent",
    )


def check_version_source() -> None:
    source = (ROOT / "fesim_version_info.ado").read_text(encoding="utf-8")
    match = re.search(r'return local version "([^"]+)"', source)
    require(match is not None, "fesim_version_info.ado has no version return")
    version = match.group(1)
    required_mentions = {
        "fesim.sthlp": (ROOT / "fesim.sthlp").read_text(encoding="utf-8")[:300],
        "README.md": (ROOT / "README.md").read_text(encoding="utf-8"),
        "CITATION.cff": (ROOT / "CITATION.cff").read_text(encoding="utf-8"),
        "fesim.pkg": (ROOT / "fesim.pkg").read_text(encoding="utf-8"),
        "stata.toc": (ROOT / "stata.toc").read_text(encoding="utf-8"),
    }
    required_mentions.update(
        {
            path.name: path.read_text(encoding="utf-8").splitlines()[0]
            for path in ROOT.glob("*.ado")
        }
    )
    missing = [name for name, text in required_mentions.items() if version not in text]
    require(not missing, f"version {version} is absent from: {', '.join(missing)}")


def check_mata_build_coverage() -> None:
    build = (ROOT / "src/build_mlib.do").read_text(encoding="utf-8")
    registered = set(re.findall(r"src/(fesim_[A-Za-z0-9_]+\.mata)", build))
    actual = {path.name for path in (ROOT / "src").glob("fesim_*.mata")}
    require(
        registered == actual,
        "Mata build/source mismatch: "
        f"missing={sorted(actual - registered)}, "
        f"extra={sorted(registered - actual)}",
    )


def check_test_registration() -> None:
    runner = (ROOT / "tests/run_all.do").read_text(encoding="utf-8")
    match = re.search(r"\nlocal tests\s+(.*?)\nlocal n_tests", runner, re.DOTALL)
    require(match is not None, "cannot parse registered Stata tests")
    names = match.group(1).replace("///", " ").split()
    registered = {f"tests/{name}.do" for name in names}
    actual = {"tests/install_smoke.do", "tests/smoke.do"}
    actual.update(
        str(path.relative_to(ROOT))
        for directory in (
            ROOT / "tests/unit",
            ROOT / "tests/integration",
            ROOT / "tests/regression",
            ROOT / "tests/statistical",
            ROOT / "tests/docs",
        )
        for path in directory.glob("*.do")
    )
    require(
        registered == actual,
        "Stata runner/test mismatch: "
        f"missing={sorted(actual - registered)}, "
        f"extra={sorted(registered - actual)}",
    )


def check_runtime_dependencies() -> None:
    forbidden = re.compile(
        r"^\s*(?:shell|winexec|python|rscript|julia)\b|^\s*!\s+", re.I
    )
    violations: list[str] = []
    for path in ROOT.glob("*.ado"):
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            if forbidden.search(line):
                violations.append(f"{path.name}:{line_number}")
    require(
        not violations,
        "installed ado invokes a foreign runtime: " + ", ".join(violations),
    )


def check_help_examples() -> None:
    help_text = (ROOT / "fesim.sthlp").read_text(encoding="utf-8")
    runner = (ROOT / "fesim_run.ado").read_text(encoding="utf-8")
    require(
        "{.-}\nhelp for {cmd:fesim} "
        "{right:(Johannes F. Schmieder)}\n{.-}" in help_text,
        "fesim help lacks the shared author header",
    )
    examples = (
        "discovery",
        "simulate",
        "estimate",
        "stylized",
        "germany",
        "blocks",
        "bridges",
        "ladder",
        "paygap",
        "bm",
        "cpv", "cpv_heterogeneous", "cpv_paths", "cpv_dispersion",
        "cpv_bargaining", "cpv_akm", "cpv_movers",
        "blm_static", "blm_dynamic", "blm_matrices", "blm_akm", "blm_movers",
    )
    for example in examples:
        require(
            help_text.count(f"{{* example_start - {example}}}{{...}}") == 1,
            f"help example marker is missing or duplicated: {example}",
        )
        require(
            f"fesim_run {example} using fesim.sthlp" in help_text,
            f"help example has no run link: {example}",
        )
    require(
        help_text.count("{* example_end}{...}") == len(examples),
        "help example end-marker count is inconsistent",
    )
    require("program define fesim_run" in runner, "fesim_run is incomplete")
    require("capture restore" in runner, "fesim_run does not restore caller data")
    author = help_text[help_text.index("{title:Author}") :]
    require("{title:" not in author[len("{title:Author}") :], "Author is not final")


def check_static_workflow() -> None:
    workflow = ROOT / ".github/workflows/static.yml"
    require(workflow.is_file(), "static GitHub Actions workflow is missing")
    text = workflow.read_text(encoding="utf-8")
    for required in (
        "actions/checkout@v7",
        "python3 scripts/static_checks.py",
        "python3 -m unittest discover -s tests/static",
    ):
        require(required in text, f"static workflow omits: {required}")
    lowered = text.lower()
    require(
        "run_stata_tests.sh" not in lowered and "stata-mp" not in lowered,
        "static workflow must not invoke licensed Stata",
    )



def documentation_field(text: str, name: str) -> str:
    matches = re.findall(rf"^\| {re.escape(name)} \| (.*?) \|$", text, re.MULTILINE)
    require(len(matches) == 1, f"missing or duplicate source inventory field: {name}")
    return matches[0].strip("`")


def check_documentation_inventory() -> None:
    """Keep maintained public documentation aligned with authoritative source."""
    interface = (ROOT / "docs/interface.md").read_text(encoding="utf-8")
    patterns = (
        ("Package version", "fesim_version_info.ado", r'return local version "([^"]+)"'),
        ("Public API", "fesim_version_info.ado", r"return scalar api_level\s*=\s*(\d+)"),
        ("Mata API", "_fesim_load.ado", r"fesim_mata_api_version\(\) == (\d+)"),
        ("Registered presets", "fesim_registry.ado", r'return local qualified "([^"]+)"'),
    )
    for name, path, pattern in patterns:
        source = (ROOT / path).read_text(encoding="utf-8")
        match = re.search(pattern, source)
        require(match is not None, f"cannot parse source inventory: {name}")
        require(documentation_field(interface, name) == match.group(1),
                f"documentation/source mismatch: {name}")
    runner = (ROOT / "tests/run_all.do").read_text(encoding="utf-8")
    tests = re.search(r"\nlocal tests\s+(.*?)\nlocal n_tests", runner, re.DOTALL)
    require(tests is not None, "cannot parse Stata inventory")
    count = len(tests.group(1).replace("///", " ").split())
    require(documentation_field(interface, "Registered Stata files") == str(count),
            "documentation/source mismatch: Registered Stata files")
    presets = documentation_field(interface, "Registered presets").split()
    calibration = (ROOT / "docs/calibration.md").read_text(encoding="utf-8")
    routes = re.findall(r"^\| `([^`]+)` \|", calibration, re.MULTILINE)
    require(sorted(routes) == sorted(presets), "calibration route inventory mismatch")

    help_text = (ROOT / "fesim.sthlp").read_text(encoding="utf-8")
    markers = re.findall(r"\{marker ([\w]+)\}", help_text)
    require(len(markers) == len(set(markers)), "duplicate help navigation marker")
    targets = re.findall(r"\{help fesim##([\w]+):", help_text)
    require(set(targets).issubset(markers), "help navigation target is absent")

    documents = [ROOT / "README.md", ROOT / "CONTRIBUTING.md"]
    documents.extend((ROOT / "docs").glob("*.md"))
    documents.extend((ROOT / "tests").rglob("README.md"))
    documents.extend((ROOT / "examples").glob("README.md"))
    for document in documents:
        text = document.read_text(encoding="utf-8")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if "://" in target or target.startswith(("#", "mailto:")):
                continue
            path = target.split("#", 1)[0]
            require((document.parent / path).exists(),
                    f"document link is absent: {document.relative_to(ROOT)} -> {target}")


def main() -> int:
    checks = (
        check_whitespace,
        lambda: check_no_tracked_artifacts(tracked_files()),
        check_package_manifest,
        check_version_source,
        check_mata_build_coverage,
        check_test_registration,
        check_runtime_dependencies,
        check_help_examples,
        check_static_workflow,
        check_documentation_inventory,
    )
    try:
        for check in checks:
            check()
    except (CheckFailure, subprocess.CalledProcessError, OSError) as error:
        print(f"STATIC CHECK FAILURE: {error}", file=sys.stderr)
        return 1
    print(f"FESIM STATIC CONTRACT CHECKS PASS ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

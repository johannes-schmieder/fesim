from __future__ import annotations

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "fesim_static_checks", PROJECT_ROOT / "scripts/static_checks.py"
)
CHECKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKS)


class DocumentationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for folder in ("docs", "tests", "examples", "calibrations", "src", "scripts"):
            shutil.copytree(PROJECT_ROOT / folder, self.root / folder,
                            ignore=shutil.ignore_patterns("__pycache__"))
        for name in ("README.md", "CONTRIBUTING.md", "CITATION.cff", "LICENSE",
                     "fesim.sthlp", "fesim_version_info.ado", "fesim_registry.ado",
                     "fesim__load.ado"):
            shutil.copy2(PROJECT_ROOT / name, self.root / name)
        self.patcher = patch.object(CHECKS, "ROOT", self.root)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def change(self, name: str, old: str, new: str) -> None:
        path = self.root / name
        text = path.read_text(encoding="utf-8")
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1), encoding="utf-8")

    def test_accepts_source_without_git_or_local_receipts(self) -> None:
        self.assertFalse((self.root / ".git").exists())
        self.assertFalse((self.root / "build").exists())
        CHECKS.check_documentation_inventory()

    def test_rejects_stale_inventory_fields(self) -> None:
        path = self.root / "docs/interface.md"
        original = path.read_text()
        for name in ("Package version", "Public API", "Mata API",
                     "Registered presets", "Registered Stata files"):
            with self.subTest(field=name):
                path.write_text(original)
                value = CHECKS.documentation_field(original, name)
                self.change("docs/interface.md", f"| {name} | `{value}` |",
                            f"| {name} | `stale` |")
                with self.assertRaisesRegex(CHECKS.CheckFailure, name):
                    CHECKS.check_documentation_inventory()

    def test_rejects_missing_or_duplicate_inventory_field(self) -> None:
        path = self.root / "docs/interface.md"
        original = path.read_text()
        row = "| Public API | `1` |"
        for replacement in ("", row + "\n" + row):
            with self.subTest(replacement=replacement):
                path.write_text(original.replace(row, replacement))
                with self.assertRaisesRegex(CHECKS.CheckFailure, "missing or duplicate"):
                    CHECKS.check_documentation_inventory()

    def test_rejects_missing_or_duplicate_calibration_route(self) -> None:
        path = self.root / "docs/calibration.md"
        original = path.read_text()
        row = next(line for line in original.splitlines() if line.startswith("| `blm/static` |"))
        for replacement in ("", row + "\n" + row):
            with self.subTest(replacement=replacement):
                path.write_text(original.replace(row, replacement))
                with self.assertRaisesRegex(CHECKS.CheckFailure, "route inventory mismatch"):
                    CHECKS.check_documentation_inventory()

    def test_rejects_missing_document(self) -> None:
        (self.root / "docs/blm.md").unlink()
        with self.assertRaisesRegex(CHECKS.CheckFailure, "document link is absent"):
            CHECKS.check_documentation_inventory()

    def test_rejects_broken_help_navigation(self) -> None:
        self.change("fesim.sthlp", "{marker quickstart}", "{marker absent}")
        with self.assertRaisesRegex(CHECKS.CheckFailure, "help navigation target is absent"):
            CHECKS.check_documentation_inventory()

    def test_rejects_duplicate_help_marker(self) -> None:
        self.change("fesim.sthlp", "{marker quickstart}", "{marker quickstart}\n{marker quickstart}")
        with self.assertRaisesRegex(CHECKS.CheckFailure, "duplicate help navigation marker"):
            CHECKS.check_documentation_inventory()

    def test_checks_relative_links_from_each_document(self) -> None:
        self.change("README.md", "(docs/blm.md)", "(docs/missing-model.md)")
        with self.assertRaisesRegex(CHECKS.CheckFailure, "README.md -> docs/missing-model.md"):
            CHECKS.check_documentation_inventory()


if __name__ == "__main__":
    unittest.main()

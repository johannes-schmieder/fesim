from __future__ import annotations

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "fesim_packaging_checks", PROJECT_ROOT / "scripts/static_checks.py"
)
CHECKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKS)


class PackageFilenameTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        manifest = PROJECT_ROOT / "fesim.pkg"
        shutil.copy2(manifest, self.root / "fesim.pkg")
        for line in manifest.read_text().splitlines():
            if not line.startswith("f "):
                continue
            name = line.split(maxsplit=1)[1]
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(PROJECT_ROOT / name, target)
        self.patcher = patch.object(CHECKS, "ROOT", self.root)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def test_accepts_prefixed_files_in_source_subdirectories(self) -> None:
        CHECKS.check_package_manifest()

    def test_rejects_unprefixed_installed_ado_help_and_mata(self) -> None:
        for original, renamed in (
            ("fesim__load.ado", "_fesim_load.ado"),
            ("fesim_license.sthlp", "license.sthlp"),
            ("src/fesim_types.mata", "src/types.mata"),
        ):
            with self.subTest(installed_file=renamed):
                manifest = self.root / "fesim.pkg"
                text = manifest.read_text()
                (self.root / original).rename(self.root / renamed)
                manifest.write_text(text.replace(f"f {original}\n", f"f {renamed}\n"))
                try:
                    with self.assertRaisesRegex(
                        CHECKS.CheckFailure, "installed filename must start with fesim"
                    ):
                        CHECKS.check_package_manifest()
                finally:
                    (self.root / renamed).rename(self.root / original)
                    manifest.write_text(text)


if __name__ == "__main__":
    unittest.main()

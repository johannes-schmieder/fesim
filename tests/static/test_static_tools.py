from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
VERIFIER = PROJECT_ROOT / "scripts/verify_stata_receipt.py"


class ReceiptVerifierTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name)
        subprocess.run(["git", "init", "-b", "main", str(self.repo)], check=True)
        subprocess.run(
            ["git", "-C", str(self.repo), "config", "user.name", "Fesim Test"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(self.repo), "config", "user.email", "test@example.invalid"],
            check=True,
        )
        (self.repo / ".gitignore").write_text("build/\n", encoding="utf-8")
        (self.repo / "source.ado").write_text("version 19.0\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(self.repo), "commit", "-m", "fixture"],
            check=True,
            capture_output=True,
        )
        self.sha = subprocess.run(
            ["git", "-C", str(self.repo), "rev-parse", "HEAD"],
            check=True,
            text=True,
            capture_output=True,
        ).stdout.strip()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_receipt(self, **overrides: object) -> Path:
        data: dict[str, object] = {
            "repository": str(self.repo),
            "sha": self.sha,
            "branch": "main",
            "stata_version": "19",
            "stata_flavor": "MP",
            "os": "Unix",
            "architecture": "test",
            "suite": "quick",
            "exit_code": 0,
            "tests_passed": 15,
            "tests_failed": 0,
            "mlib_rebuilt": True,
            "status": "accepted",
        }
        data.update(overrides)
        receipt_dir = self.repo / "build/test-results"
        receipt_dir.mkdir(parents=True, exist_ok=True)
        receipt = receipt_dir / f"receipt-{data['sha']}.json"
        receipt.write_text(json.dumps(data), encoding="utf-8")
        return receipt

    def run_verifier(self, receipt: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(VERIFIER), str(receipt), self.sha],
            cwd=self.repo,
            text=True,
            capture_output=True,
        )

    def test_accepts_exact_clean_receipt(self) -> None:
        result = self.run_verifier(self.write_receipt())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(self.sha, result.stdout)

    def test_rejects_stale_sha(self) -> None:
        result = self.run_verifier(self.write_receipt(sha="0" * 40))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not equal checked-out HEAD", result.stderr)

    def test_rejects_dirty_checkout(self) -> None:
        receipt = self.write_receipt()
        (self.repo / "source.ado").write_text("version 19.0\n* dirty\n", encoding="utf-8")
        result = self.run_verifier(receipt)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source changes", result.stderr)

    def test_rejects_nonaccepted_status(self) -> None:
        result = self.run_verifier(self.write_receipt(status="failed"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("status is not accepted", result.stderr)


if __name__ == "__main__":
    unittest.main()

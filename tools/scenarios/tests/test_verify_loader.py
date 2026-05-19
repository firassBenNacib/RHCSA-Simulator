from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from verify_scenario_solutions import load_manifest  # noqa: E402


class VerifyLoaderTests(unittest.TestCase):
    def test_load_manifest_uses_requested_track(self) -> None:
        manifest = load_manifest("exam", "rhcsa10-mock-exam-a", "rhcsa10")
        self.assertEqual(manifest["id"], "rhcsa10-mock-exam-a")
        self.assertEqual(manifest["rhel_major"], 10)
        self.assertEqual(
            manifest["vm_scripts"],
            {"client": "scripts/client.sh", "server": "scripts/server.sh"},
        )

    def test_load_manifest_normalizes_standalone_lab_verification_tasks(self) -> None:
        manifest = load_manifest("lab", "lab-01-hostname-resolution", "rhcsa10")
        lab = manifest["content"]["lab"]
        self.assertEqual(len(lab["tasks"]), 2)
        self.assertEqual(len(lab["checks"]), 2)
        self.assertIn("getent hosts server10.lab.example", lab["checks"][1])

    def test_rhcsa10_lab_manifest_includes_generator_reset_scripts(self) -> None:
        manifest = load_manifest("lab", "lab-42-autofs", "rhcsa10")
        self.assertEqual(
            manifest["vm_scripts"],
            {"client": "scripts/client.sh", "server": "scripts/server.sh"},
        )
        self.assertTrue(manifest["flags"]["requires_server"])


if __name__ == "__main__":
    unittest.main()

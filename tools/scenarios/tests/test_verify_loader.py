from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from smoke_test_scenarios import parse_baseline_status  # noqa: E402
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
        self.assertEqual(len(lab["tasks"]), 3)
        self.assertEqual(len(lab["checks"]), 3)
        self.assertEqual(manifest["scope"], "client-server")
        self.assertIn("getent hosts server10.lab.example", lab["checks"][2])

    def test_rhcsa10_lab_manifest_includes_generator_reset_scripts(self) -> None:
        manifest = load_manifest("lab", "lab-42-autofs", "rhcsa10")
        self.assertEqual(
            manifest["vm_scripts"],
            {"client": "scripts/client.sh", "server": "scripts/server.sh"},
        )
        self.assertTrue(manifest["flags"]["requires_server"])

    def test_parse_baseline_status_accepts_boxed_cli_output(self) -> None:
        output = "\n".join([
            "╭─ RHCSA Status ─────────────────────────────╮",
            "│ Profile     RHEL10                         │",
            "│ Track       RHCSA10                        │",
            "│ Baseline    ready                          │",
            "╰────────────────────────────────────────────╯",
        ])
        self.assertEqual(parse_baseline_status(output), "ready")

    def test_rhcsa10_exams_render_client_server_systems(self) -> None:
        tasks_path = Path("scenarios/exams/rhcsa10/rhcsa10-mock-exam-b/EXAM_TASKS.md")
        content = tasks_path.read_text(encoding="utf-8")
        self.assertIn("### Systems\n- client\n- server", content)


if __name__ == "__main__":
    unittest.main()

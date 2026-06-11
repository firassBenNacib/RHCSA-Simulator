from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from generate_rhcsa10_scenarios import _lvm_mount_check, _prefix_client_task  # noqa: E402


class Rhcsa10GeneratorTests(unittest.TestCase):
    def test_lvm_mount_check_accepts_stable_fstab_sources(self) -> None:
        check = _lvm_mount_check("a")

        self.assertIn("$1 == dev", check)
        self.assertIn("$1 == mapper", check)
        self.assertIn('$1 == "UUID=" uuid', check)
        self.assertIn('$1 == "/dev/disk/by-uuid/" uuid', check)
        self.assertIn("$3 == \"xfs\"", check)

    def test_prefix_client_task_preserves_explicit_targets(self) -> None:
        self.assertEqual(
            _prefix_client_task("Set hostname to clientc.exam10.lab."),
            "On client, set hostname to clientc.exam10.lab.",
        )
        self.assertEqual(
            _prefix_client_task("(server) Configure persistent journal storage."),
            "(server) Configure persistent journal storage.",
        )


if __name__ == "__main__":
    unittest.main()

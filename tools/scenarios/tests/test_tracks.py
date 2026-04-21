from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from rhcsa_scenarios.tracks import manifest_tracks, normalize_track


class TrackTests(unittest.TestCase):
    def test_normalize_aliases(self) -> None:
        self.assertEqual(normalize_track("RHCSA9"), "rhcsa9")
        self.assertEqual(normalize_track("rhel-10"), "rhcsa10")
        self.assertEqual(normalize_track("all"), "all")

    def test_manifest_defaults_to_rhcsa9(self) -> None:
        self.assertEqual(manifest_tracks(None), {"rhcsa9"})
        self.assertEqual(manifest_tracks([]), {"rhcsa9"})

    def test_manifest_rejects_non_list(self) -> None:
        with self.assertRaises(SystemExit):
            manifest_tracks("rhcsa10")


if __name__ == "__main__":
    unittest.main()


from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from audit_scenarios import audit_exam_similarity_limits  # noqa: E402


class AuditScenarioTests(unittest.TestCase):
    def test_rhcsa10_similarity_threshold_is_enforced(self) -> None:
        findings = audit_exam_similarity_limits(
            [
                ("rhcsa10", "rhcsa10-mock-exam-a", "rhcsa10-mock-exam-b", 0.91),
                ("rhcsa10", "rhcsa10-mock-exam-c", "rhcsa10-mock-exam-d", 0.90),
            ]
        )

        self.assertEqual(len(findings), 1)
        self.assertIn("rhcsa10-mock-exam-a and rhcsa10-mock-exam-b are too similar", findings[0].message)
        self.assertIn("max 0.90", findings[0].message)

    def test_rhcsa9_keeps_existing_stricter_threshold(self) -> None:
        findings = audit_exam_similarity_limits(
            [
                ("rhcsa9", "mock-exam-a", "mock-exam-b", 0.91),
                ("rhcsa9", "mock-exam-c", "mock-exam-d", 0.96),
            ]
        )

        self.assertEqual(len(findings), 1)
        self.assertIn("mock-exam-c and mock-exam-d are too similar", findings[0].message)
        self.assertIn("max 0.95", findings[0].message)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from rhcsa_scenarios.text import normalize_task_text


class NormalizeTaskTextTests(unittest.TestCase):
    def test_single_line_without_punctuation(self) -> None:
        self.assertEqual(normalize_task_text("Create user alice"), "Create user alice.")

    def test_single_line_with_period(self) -> None:
        self.assertEqual(normalize_task_text("Create user alice."), "Create user alice.")

    def test_single_line_with_colon(self) -> None:
        self.assertEqual(normalize_task_text("Requirements:"), "Requirements:")

    def test_multiline_strips_dedent(self) -> None:
        text = "    Line one\n    Line two"
        self.assertEqual(normalize_task_text(text), "Line one\nLine two")

    def test_trailing_whitespace_removed(self) -> None:
        self.assertEqual(normalize_task_text("hello   \nworld  \n"), "hello\nworld")

    def test_empty_string(self) -> None:
        self.assertEqual(normalize_task_text(""), "")


if __name__ == "__main__":
    unittest.main()

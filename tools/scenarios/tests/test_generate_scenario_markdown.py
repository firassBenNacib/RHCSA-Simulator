from __future__ import annotations

import sys
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_ROOT))

from generate_scenario_markdown import get_task_title, render_task_body  # noqa: E402


class GenerateScenarioMarkdownTests(unittest.TestCase):
    def test_key_value_labels_preserve_dns_acronym(self) -> None:
        rendered = render_task_body(
            """
            IP address: 192.168.122.10/24
            DNS: 192.168.122.3
            BaseOS: http://server/repo/BaseOS/
            AppStream: http://server/repo/AppStream/
            """
        )

        self.assertIn("- **IP address:** 192.168.122.10/24", rendered)
        self.assertIn("- **DNS:** 192.168.122.3", rendered)
        self.assertIn("- **BaseOS:** http://server/repo/BaseOS/", rendered)
        self.assertIn("- **AppStream:** http://server/repo/AppStream/", rendered)
        self.assertNotIn("**Dns:**", rendered)

    def test_task_titles_use_sentence_style_with_acronyms(self) -> None:
        self.assertEqual(
            get_task_title(["Client RPM Repositories"], 0, "On client, configure repositories."),
            "Client RPM repositories",
        )
        self.assertEqual(
            get_task_title(["Client Server NFS Mount"], 0, "On client, mount server:/exports/data."),
            "Client server NFS mount",
        )
        self.assertEqual(
            get_task_title(["Configure flatpak remote rhcsa10"], 0, "On client, configure a remote."),
            "Configure Flatpak remote rhcsa10",
        )


if __name__ == "__main__":
    unittest.main()

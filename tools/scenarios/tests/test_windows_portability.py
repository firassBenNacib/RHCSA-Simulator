from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


class WindowsPortabilityTests(unittest.TestCase):
    def test_vagrantfile_uses_current_iso_defaults_and_future_globs(self) -> None:
        content = (ROOT / "Vagrantfile").read_text(encoding="utf-8")

        self.assertIn('"rhel9" => "rhel-9.8-x86_64-dvd.iso"', content)
        self.assertIn('"rhel10" => "rhel-10.2-x86_64-dvd.iso"', content)
        self.assertIn('"rhel9" => "rhel-9.*-x86_64-dvd.iso"', content)
        self.assertIn('"rhel10" => "rhel-10.*-x86_64-dvd.iso"', content)

    def test_rhcsa_iso_override_supports_relative_and_absolute_paths(self) -> None:
        content = (ROOT / "Vagrantfile").read_text(encoding="utf-8")

        self.assertIn('override = ENV.fetch("RHCSA_ISO", "").strip', content)
        self.assertIn("File.expand_path(override, __dir__)", content)
        self.assertRegex(content, re.compile(r'Dir\.glob\(File\.join\(__dir__, ISO_GLOB_BY_PROFILE\.fetch\(profile\)\)\)'))

    def test_repository_has_no_user_specific_windows_paths(self) -> None:
        checked_extensions = {".md", ".ps1", ".py", ".rb", ".json", ""}
        forbidden = ("C:" + "\\Users\\MSI", "C:" + "/Users/MSI")

        offenders: list[str] = []
        for path in ROOT.rglob("*"):
            if any(part in {".git", ".vagrant", ".build", "__pycache__"} for part in path.parts):
                continue
            if path.is_dir() or path.suffix not in checked_extensions:
                continue
            try:
                content = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if any(token in content for token in forbidden):
                offenders.append(str(path.relative_to(ROOT)))

        self.assertEqual([], offenders)


if __name__ == "__main__":
    unittest.main()

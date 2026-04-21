#!/usr/bin/env python3
from __future__ import annotations

import runpy
import sys
from pathlib import Path


def run_tool(filename: str) -> int:
    root = Path(__file__).resolve().parents[1]
    tool_dir = root / "tools" / "scenarios"
    tool_path = tool_dir / filename
    if not tool_path.is_file():
        raise FileNotFoundError(f"Scenario tool not found: {tool_path}")
    sys.path.insert(0, str(tool_dir))
    runpy.run_path(str(tool_path), run_name="__main__")
    return 0

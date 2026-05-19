#!/usr/bin/env python3
from pathlib import Path
import runpy
import sys


def run_tool(script_name: str) -> int:
    project_root = Path(__file__).resolve().parents[1]
    tool_dir = project_root / "tools" / "scenarios"
    script_path = tool_dir / script_name
    sys.path[:0] = [str(tool_dir), str(project_root)]
    sys.argv[0] = str(script_path)
    runpy.run_path(str(script_path), run_name="__main__")
    return 0

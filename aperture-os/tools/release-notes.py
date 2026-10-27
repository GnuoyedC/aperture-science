#!/usr/bin/env python3
"""Print the CHANGELOG.md section of one version (used by CI for the GitLab release notes).
  tools/release-notes.py 1.0.0
"""
import pathlib
import re
import sys

version = sys.argv[1]
text = (pathlib.Path(__file__).resolve().parent.parent / "CHANGELOG.md").read_text(encoding="utf-8")
match = re.search(rf"^## \[?{re.escape(version)}\]?.*?\n(.*?)(?=^## |\Z)", text, re.M | re.S)
if not match:
    sys.exit(f"CHANGELOG.md has no section for {version}")
print(match.group(1).strip())

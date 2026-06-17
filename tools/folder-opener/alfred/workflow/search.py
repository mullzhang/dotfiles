#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path


def alfred(items):
    print(json.dumps({"items": items}, ensure_ascii=False))


query = sys.argv[1].strip().casefold() if len(sys.argv) > 1 else ""
base = os.environ.get("FOLDER_OPENER_BASE", "").strip()

if not base:
    alfred(
        [
            {
                "title": "FOLDER_OPENER_BASE is not set",
                "subtitle": "Set it in the workflow environment variables.",
                "valid": False,
            }
        ]
    )
    sys.exit(0)

base_path = Path(base).expanduser()
if not base_path.is_dir():
    alfred(
        [
            {
                "title": "Folder base does not exist",
                "subtitle": str(base_path),
                "valid": False,
            }
        ]
    )
    sys.exit(0)

matches = []
for child in sorted(base_path.iterdir(), key=lambda path: path.name.casefold()):
    if not child.is_dir():
        continue
    if query and query not in child.name.casefold():
        continue
    matches.append(
        {
            "title": child.name,
            "subtitle": str(child),
            "arg": str(child),
            "type": "file",
            "uid": str(child),
        }
    )

if not matches:
    alfred(
        [
            {
                "title": "No matching folders",
                "subtitle": str(base_path),
                "valid": False,
            }
        ]
    )
    sys.exit(0)

alfred(matches[:50])

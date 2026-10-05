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

base_paths = list(dict.fromkeys(
    Path(value.strip()).expanduser() for value in base.split(",") if value.strip()
))
for base_path in base_paths:
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
children = (child for base_path in base_paths for child in base_path.iterdir())
for child in sorted(children, key=lambda path: (path.name.casefold(), str(path))):
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
                "subtitle": " | ".join(str(path) for path in base_paths),
                "valid": False,
            }
        ]
    )
    sys.exit(0)

alfred(matches[:50])

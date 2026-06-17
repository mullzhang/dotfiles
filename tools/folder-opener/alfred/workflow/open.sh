#!/bin/zsh
set -euo pipefail

folder="${1:-}"

if [[ -z "$folder" || ! -d "$folder" ]]; then
  exit 1
fi

open "$folder"

#!/usr/bin/env bash
set -euo pipefail

threshold="${1:-${CCN_THRESHOLD:-15}}"
if [[ "${1:-}" == "--" ]]; then
  threshold="${2:-${CCN_THRESHOLD:-15}}"
fi

if ! printf '%s' "$threshold" | grep -Eq '^[0-9]+$'; then
  echo "CCN threshold must be an integer: '$threshold'" >&2
  exit 2
fi

printf 'nloc,ccn,token_count,parameter_count,length,location,file,function,long_name,start_line,end_line\n'
uv run lizard -l python --csv | awk -F, -v th="$threshold" '$2+0 >= th'

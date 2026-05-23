#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  import_json_to_1password.sh <input.json> [options]

Optional options:
  --title <title>      Base title for created item(s)
  --category <name>    Item category (default: Login)
  --vault <name>       Target vault
  --tags <csv>         Comma-separated tags
  --dry-run            Run op in dry-run mode
  -h, --help           Show this help

Behavior:
  - If input JSON is an object: create 1 item.
  - If input JSON is an array: create 1 item per element.
  - JSON content is flattened and added as custom text fields:
      <flattened_path>[text]=<value>
    (internally, dots in field names are escaped for 1Password CLI parsing)
USAGE
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' command is required." >&2
    exit 1
  fi
}

normalize_field_name() {
  local raw="$1"
  local normalized
  normalized="$(printf '%s' "$raw" | tr -c '[:alnum:]_.-' '_')"
  normalized="${normalized##_}"
  normalized="${normalized%%_}"
  if [[ -z "$normalized" ]]; then
    normalized="field"
  fi
  printf '%s' "$normalized"
}

escape_assignment_key() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//./\\.}"
  raw="${raw//=/\\=}"
  printf '%s' "$raw"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

json_file=""
title=""
category="Login"
vault=""
tags=""
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --title)
      [[ $# -ge 2 ]] || { echo "Error: --title requires a value." >&2; exit 1; }
      title="$2"
      shift 2
      ;;
    --category)
      [[ $# -ge 2 ]] || { echo "Error: --category requires a value." >&2; exit 1; }
      category="$2"
      shift 2
      ;;
    --vault)
      [[ $# -ge 2 ]] || { echo "Error: --vault requires a value." >&2; exit 1; }
      vault="$2"
      shift 2
      ;;
    --tags)
      [[ $# -ge 2 ]] || { echo "Error: --tags requires a value." >&2; exit 1; }
      tags="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --*)
      echo "Error: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -n "$json_file" ]]; then
        echo "Error: only one input JSON file is allowed." >&2
        exit 1
      fi
      json_file="$1"
      shift
      ;;
  esac
done

if [[ -z "$json_file" ]]; then
  echo "Error: input JSON file is required." >&2
  usage
  exit 1
fi

if [[ ! -f "$json_file" ]]; then
  echo "Error: file not found: $json_file" >&2
  exit 1
fi

require_command jq
require_command op

if ! jq -e . "$json_file" >/dev/null 2>&1; then
  echo "Error: invalid JSON: $json_file" >&2
  exit 1
fi

total_items="$(jq -r 'if type == "array" then length else 1 end' "$json_file")"
if [[ "$total_items" -eq 0 ]]; then
  echo "Error: input array is empty." >&2
  exit 1
fi

if [[ -z "$title" ]]; then
  base_name="$(basename "$json_file")"
  title="${base_name%.*}"
fi

count=0
while IFS= read -r item; do
  count=$((count + 1))

  item_title="$title"
  if [[ "$total_items" -gt 1 ]]; then
    item_title="${title} #${count}"
  fi

  create_args=(
    item create
    --category "$category"
    --title "$item_title"
  )

  if [[ -n "$vault" ]]; then
    create_args+=(--vault "$vault")
  fi

  if [[ -n "$tags" ]]; then
    create_args+=(--tags "$tags")
  fi

  if [[ "$dry_run" == true ]]; then
    create_args+=(--dry-run)
  fi

  while IFS= read -r field_json; do
    raw_path="$(jq -r '.path' <<<"$field_json")"
    value="$(jq -r '.value' <<<"$field_json")"

    field_name="$(normalize_field_name "$raw_path")"
    escaped_field_name="$(escape_assignment_key "$field_name")"

    create_args+=("${escaped_field_name}[text]=${value}")
  done < <(
    jq -c '
      if (type == "object" or type == "array") then
        [paths(scalars) as $p
          | select(getpath($p) != null)
          | {
              path: ($p | map(tostring) | join(".")),
              value: (getpath($p) | tostring)
            }
        ] | .[]
      else
        { path: "value", value: tostring }
      end
    ' <<<"$item"
  )

  op "${create_args[@]}" </dev/null >/dev/null
  echo "Created item: $item_title"
done < <(jq -c 'if type == "array" then .[] else . end' "$json_file")

echo "Done. Imported $count item(s)."

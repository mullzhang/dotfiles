#!/usr/bin/env bash
set -euo pipefail

local_skills_dir="$HOME/dotfiles/local/apm/.apm/skills"
global_skills_dir="$HOME/.apm/skills"

if [[ -d "$local_skills_dir" ]]; then
  if [[ -L "$global_skills_dir" ]] ||
     { [[ -e "$global_skills_dir" ]] && [[ ! -f "$global_skills_dir/.dotfiles-managed" ]]; }; then
    echo "Refusing to replace existing path: $global_skills_dir" >&2
    exit 1
  fi
  mkdir -p "$global_skills_dir"
  touch "$global_skills_dir/.dotfiles-managed"
  rsync -a --checksum --delete --exclude '__pycache__/' --exclude '.dotfiles-managed' \
    "$local_skills_dir/" "$global_skills_dir/"
fi

for skill_dir in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
  [[ -d "$skill_dir" ]] || continue
  find "$skill_dir" -type d -name __pycache__ -prune -exec rm -rf {} +
done

apm install --global --frozen

apm_manifest="$HOME/.apm/apm.yml"
if [[ ! -L "$apm_manifest" ]]; then
  apm compile --global
  exit
fi

# Global compile rejects the manifest symlink created by setup.sh.
manifest_link="$(readlink "$apm_manifest")"
tmp_dir="$(mktemp -d)"

cleanup() {
  local exit_status=$?
  ln -sf "$manifest_link" "$apm_manifest"
  rm -rf "$tmp_dir"
  return "$exit_status"
}
trap cleanup EXIT

cp "$apm_manifest" "$tmp_dir/apm.yml"
mv "$tmp_dir/apm.yml" "$apm_manifest"
apm compile --global

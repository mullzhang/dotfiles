#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  apm_install.sh <shared|local> <install|uninstall> <package> [apm args...]

Examples:
  apm_install.sh local install Sigma-i/sigmai-shared-skills
  apm_install.sh shared install github/awesome-copilot/skills/gh-cli
  apm_install.sh local uninstall Sigma-i/sigmai-shared-skills
USAGE
}

scope="${1:-}"
action="${2:-}"

if [[ $# -lt 3 ]]; then
  usage >&2
  exit 2
fi

shift 2

case "$scope" in
  shared|local) ;;
  *)
    echo "scope must be 'shared' or 'local': $scope" >&2
    exit 2
    ;;
esac

case "$action" in
  install|uninstall) ;;
  *)
    echo "action must be 'install' or 'uninstall': $action" >&2
    exit 2
    ;;
esac

dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
apm_dir="$HOME/.apm"
mkdir -p "$apm_dir" "$dotfiles_dir/local/apm"

shared_manifest="$dotfiles_dir/apm/apm.yml"
shared_lock="$dotfiles_dir/apm/apm.lock.yaml"
local_manifest="$dotfiles_dir/local/apm/apm.yml"
local_lock="$dotfiles_dir/local/apm/apm.lock.yaml"

if [[ "$scope" == "local" && ! -f "$local_manifest" ]]; then
  cp "$shared_manifest" "$local_manifest"
fi

if [[ ! -f "$local_manifest" ]]; then
  cp "$shared_manifest" "$local_manifest"
fi

restore_local_links() {
  ln -sf "$local_manifest" "$apm_dir/apm.yml"
  if [[ -f "$local_lock" ]]; then
    ln -sf "$local_lock" "$apm_dir/apm.lock.yaml"
  else
    rm -f "$apm_dir/apm.lock.yaml"
  fi
}

if [[ "$scope" == "shared" ]]; then
  manifest="$shared_manifest"
  lock="$shared_lock"
  trap restore_local_links EXIT
else
  manifest="$local_manifest"
  lock="$local_lock"
fi

ln -sf "$manifest" "$apm_dir/apm.yml"
if [[ -f "$lock" ]]; then
  ln -sf "$lock" "$apm_dir/apm.lock.yaml"
else
  rm -f "$apm_dir/apm.lock.yaml"
fi

apm "$action" --global "$@"

if [[ -f "$apm_dir/apm.lock.yaml" && ! -L "$apm_dir/apm.lock.yaml" ]]; then
  cp "$apm_dir/apm.lock.yaml" "$lock"
  ln -sf "$lock" "$apm_dir/apm.lock.yaml"
fi

if [[ "$scope" == "local" ]]; then
  echo "Updated local APM config: $local_manifest" >&2
else
  echo "Updated shared APM config: $shared_manifest" >&2
  echo "Restored active APM config to local: $local_manifest" >&2
fi

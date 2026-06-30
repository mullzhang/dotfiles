#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  apm_install.sh <shared|local> <install|uninstall> <package> [apm args...]
  apm_install.sh <shared|local> <update>

Examples:
  apm_install.sh local install Sigma-i/sigmai-shared-skills
  apm_install.sh shared install github/awesome-copilot/skills/gh-cli
  apm_install.sh local uninstall Sigma-i/sigmai-shared-skills
  apm_install.sh local update
USAGE
}

scope="${1:-}"
action="${2:-}"

if [[ $# -lt 2 ]]; then
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
  install|uninstall|update) ;;
  *)
    echo "action must be 'install', 'uninstall', or 'update': $action" >&2
    exit 2
    ;;
esac

case "$action" in
  install|uninstall)
    if [[ $# -lt 1 ]]; then
      usage >&2
      exit 2
    fi
    ;;
  update)
    if [[ $# -ne 0 ]]; then
      echo "'$action' updates the full dependency graph and does not accept package args" >&2
      exit 2
    fi
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
  elif [[ -f "$shared_lock" ]]; then
    ln -sf "$shared_lock" "$apm_dir/apm.lock.yaml"
  else
    rm -f "$apm_dir/apm.lock.yaml"
  fi
}

prune_orphaned_skill_cache() {
  local lock_file="${1:?lock file is required}"

  [[ -f "$lock_file" ]] || return 0
  command -v ruby >/dev/null 2>&1 || return 0

  ruby -ryaml -rpathname -rfileutils -e '
    apm_dir = Pathname(ARGV[0]).realpath
    lock = YAML.load_file(ARGV[1]) || {}
    module_dir = apm_dir + "apm_modules"
    exit 0 unless module_dir.directory?

    virtual_paths = []
    package_roots = []

    Array(lock["dependencies"]).each do |dep|
      repo_url = dep["repo_url"]
      next unless repo_url

      root = module_dir + repo_url
      if dep["is_virtual"] && dep["virtual_path"]
        virtual_paths << (root + dep["virtual_path"]).cleanpath
      else
        package_roots << root.cleanpath
      end
    end

    Dir.glob((module_dir + "**/SKILL.md").to_s).each do |skill_file|
      skill_dir = Pathname(skill_file).dirname.cleanpath
      keep = virtual_paths.any? { |path| skill_dir == path } ||
             package_roots.any? { |path| skill_dir.to_s.start_with?(path.to_s + "/") }
      next if keep

      FileUtils.rm_rf(skill_dir)
      warn "  [-] pruned orphaned cached skill: #{skill_dir}"
    end
  ' "$apm_dir" "$lock_file"
}

if [[ "$scope" == "shared" ]]; then
  manifest="$shared_manifest"
  lock="$shared_lock"
else
  manifest="$local_manifest"
  lock="$local_lock"
fi

tmp_dir="$(mktemp -d)"
tmp_manifest="$tmp_dir/apm.yml"
tmp_lock="$tmp_dir/apm.lock.yaml"
original_lock="$tmp_dir/original.apm.lock.yaml"

cleanup() {
  local status=$?
  if [[ "$status" -ne 0 ]]; then
    prune_orphaned_skill_cache "$original_lock" || true
  fi
  restore_local_links
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

cp "$manifest" "$tmp_manifest"
if [[ -f "$lock" ]]; then
  cp "$lock" "$tmp_lock"
  cp "$lock" "$original_lock"
elif [[ "$scope" == "local" && -f "$shared_lock" ]]; then
  cp "$shared_lock" "$original_lock"
else
  printf "lockfile_version: '1'\ndependencies: []\n" >"$original_lock"
fi

ln -sf "$tmp_manifest" "$apm_dir/apm.yml"
ln -sf "$tmp_lock" "$apm_dir/apm.lock.yaml"

case "$action" in
  install)
    apm install --global --refresh --update "$@"
    ;;
  uninstall)
    apm uninstall --global "$@"
    ;;
  update)
    apm update --global --yes --target agent-skills
    ;;
esac

cp "$tmp_manifest" "$manifest"
if [[ -f "$tmp_lock" ]]; then
  cp "$tmp_lock" "$lock"
else
  rm -f "$lock"
fi

prune_orphaned_skill_cache "$tmp_lock"

if [[ "$scope" == "local" ]]; then
  echo "Updated local APM config: $local_manifest" >&2
else
  echo "Updated shared APM config: $shared_manifest" >&2
  echo "Restored active APM config to local: $local_manifest" >&2
fi

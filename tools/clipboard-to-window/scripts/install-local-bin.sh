#!/bin/zsh
set -euo pipefail

repo_dir="${0:a:h}/.."
bin_dir="$HOME/.local/bin"

swift build -c release --package-path "$repo_dir"

mkdir -p "$bin_dir"
install -m 755 "$repo_dir/.build/release/clipboard-to-window" "$bin_dir/clipboard-to-window"

echo "$bin_dir/clipboard-to-window"

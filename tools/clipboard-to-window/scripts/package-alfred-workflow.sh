#!/bin/zsh
set -euo pipefail

repo_dir="${0:a:h}/.."
workflow_src="$repo_dir/alfred/workflow"
package_dir="$repo_dir/alfred/build/Clipboard To Window"
dist_dir="$repo_dir/dist"

rm -rf "$package_dir"
mkdir -p "$package_dir" "$dist_dir"

cp "$workflow_src/info.plist" "$package_dir/info.plist"
cp "$workflow_src/run.sh" "$package_dir/run.sh"
chmod +x "$package_dir/run.sh"

export COPYFILE_DISABLE=1
rm -f "$dist_dir/Clipboard To Window.alfredworkflow"
pushd "$package_dir" >/dev/null
zip -X -q -r "$dist_dir/Clipboard To Window.alfredworkflow" .
popd >/dev/null

echo "$dist_dir/Clipboard To Window.alfredworkflow"

#!/bin/zsh
set -euo pipefail

repo_dir="${0:a:h}/.."
workflow_src="$repo_dir/alfred/workflow"
package_dir="$repo_dir/alfred/build/Folder Opener"
dist_dir="$repo_dir/dist"

rm -rf "$package_dir"
mkdir -p "$package_dir" "$dist_dir"

cp "$workflow_src/info.plist" "$package_dir/info.plist"
cp "$workflow_src/open.sh" "$package_dir/open.sh"
cp "$workflow_src/search.py" "$package_dir/search.py"
chmod +x "$package_dir/open.sh" "$package_dir/search.py"

export COPYFILE_DISABLE=1
rm -f "$dist_dir/Folder Opener.alfredworkflow"
pushd "$package_dir" >/dev/null
zip -X -q -r "$dist_dir/Folder Opener.alfredworkflow" .
popd >/dev/null

echo "$dist_dir/Folder Opener.alfredworkflow"

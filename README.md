# dotfiles

## Scripts and tasks

Keep script addition cheap.

- Register tasks in `mise_config.toml` so they appear in the Ctrl+T mise task picker.
- When adding or updating a reusable script, update `mise_config.toml` in the same change or state why no task is needed.
- Keep short commands inline in `mise_config.toml`.
- Move longer implementations into `scripts/` and call them from `mise_config.toml`.
- Preserve implementation-oriented extensions such as `.py` and `.sh` in `scripts/`.
- Avoid separate `bin/` or `mise-tasks/` wrappers unless there is a specific need.

Examples:

```text
mise_config.toml                  # task catalog shown by mise
scripts/log_level_stats.py        # longer implementation called by a task
scripts/import_json_to_1password.sh
scripts/osrm/Makefile             # support file used by OSRM tasks
```

## Shared assets

Marp themes live under `marp/themes/`:

```text
marp/themes/marp-metropolis.css
marp/themes/marp-multi-column.css
marp/examples/minimal.md
```

Use them from Marp by passing the theme file path, or by registering these
paths in editor-specific Marp settings.

Minimal render example:

```sh
marp --theme marp/themes/marp-metropolis.css marp/examples/minimal.md
```

Matplotlib styles live under `matplotlib/stylelib/`:

```text
matplotlib/stylelib/my_setting.mplstyle
matplotlib/examples/minimal_style.py
```

`setup.sh` links this file to `~/.matplotlib/stylelib/my_setting.mplstyle` on
macOS. Use it in Python as:

```python
plt.style.use("my_setting")
```

The sample script can also be run directly from this repository:

```sh
python matplotlib/examples/minimal_style.py
```

Homebrew is managed as an environment snapshot in `homebrew/Brewfile`:

```text
homebrew/Brewfile
```

The file is generated from the current machine with `brew bundle dump --formula
--cask`, so it includes Homebrew formulae and casks only. Manage Mac App Store
apps, VS Code extensions, Cargo packages, and npm packages outside this
Brewfile.

Apply or update the snapshot through mise:

```sh
mise run brew-apply
mise run brew-check
mise run brew-dump
mise run brew-cleanup
```

`brew-apply` and `brew-check` use `--no-upgrade`, so outdated packages do not
make the snapshot fail. Use normal Homebrew upgrade commands when you want to
update installed packages. `brew-cleanup` uninstalls extra formulae and casks.

## Local files

Machine-specific overrides live under `local/`, which is ignored by git.

Supported files:

```text
local/zshrc
local/gitconfig
local/tmux.conf
local/vimrc
local/latexmkrc
local/mise.toml
```

`setup.sh` links `local/mise.toml` to `~/.config/mise/conf.d/local.toml` so it
is loaded as a global mise override. Prefer `local/zshrc` for machine-specific
environment variables consumed by tasks.

## APM

Global APM configuration is managed from `apm/`:

```text
apm/apm.yml
apm/config.json
apm/marketplaces.json
```

`setup.sh` links these files into `~/.apm/`. If a machine needs a local APM
override, put a file with the same name under `local/apm/`; setup will link the
local file instead. Keep organization-specific dependencies and lockfiles in
`local/apm/apm.yml` and `local/apm/apm.lock.yaml`.

Install APM dependencies through mise so the right manifest is selected:

```sh
mise run apm-install-local -- <package>
mise run apm-install-shared -- <package>
mise run apm-uninstall-local -- <package>
mise run apm-uninstall-shared -- <package>
mise run apm-update-local
mise run apm-update-shared
```

Update tasks fetch the latest upstream APM dependency graph, write the lockfile,
and deploy agent skills in one step. Unpinned dependencies can move to newer
upstream commits, so an upstream package with a broken transitive dependency can
break the update. Pin a dependency with `#<sha>` or `#<tag>` when reproducibility
matters.

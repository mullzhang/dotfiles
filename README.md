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

Homebrew is managed as an environment snapshot in `homebrew/Brewfile`:

```text
homebrew/Brewfile
```

The file is generated from the current machine with `brew bundle dump`, so it
may include transitive formulae and packages installed by Homebrew integrations
such as Mac App Store apps, VS Code extensions, Cargo packages, and npm
packages. Treat it as a practical snapshot, not a curated direct-dependency
list.

Apply or update the snapshot through mise:

```sh
mise run brew-apply
mise run brew-check
mise run brew-dump
mise run brew-cleanup
```

`brew-apply` and `brew-check` use `--no-upgrade`, so outdated packages do not
make the snapshot fail. Use normal Homebrew upgrade commands when you want to
update installed packages.

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
```

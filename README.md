# dotfiles

## Scripts and tasks

Keep script addition cheap.

- Register tasks in `mise_config.toml` so they appear in the Ctrl+T mise task picker.
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

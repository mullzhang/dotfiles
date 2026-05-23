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

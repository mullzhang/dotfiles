# Folder Opener

Alfred workflow for finding a direct child folder by name and opening it in Finder.

## Configure

Set the workflow environment variable in Alfred:

```text
FOLDER_OPENER_BASE=/path/to/folders
```

Each direct child directory under `FOLDER_OPENER_BASE` is searchable.

## Use

In Alfred:

```text
fld folder-name
```

Select a result and press Enter to open that folder in Finder.

## Package

```sh
scripts/package-alfred-workflow.sh
```

Then import:

```text
dist/Folder Opener.alfredworkflow
```

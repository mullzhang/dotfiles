# Folder Opener

Alfred workflow for finding a direct child folder by name and opening it in Finder.

## Configure

Set the workflow environment variable in Alfred:

```text
FOLDER_OPENER_BASE=/path/to/folders-a,/path/to/folders-b
```

Separate parent folder paths with commas. Spaces around each path are ignored.
Each direct child directory under these parent folders is searchable.
Folder paths containing commas cannot be used with this format.

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

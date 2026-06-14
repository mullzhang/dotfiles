# Clipboard To Window

Display the current macOS clipboard image in a new native window.

## Build

```sh
swift build -c release
```

The executable is created at:

```sh
.build/release/clipboard-to-window
```

## Run

Copy an image or screenshot to the clipboard, then run:

```sh
swift run clipboard-to-window
```

Or after building:

```sh
.build/release/clipboard-to-window
```

If the clipboard does not contain an image, the command exits with an error message.

## Save

After the image window opens, press `Command-S` or choose `File > Save Image...`.
The app saves the displayed image as a PNG through the standard macOS save dialog.

## Alfred Workflow

Install the executable to `~/.local/bin`:

```sh
scripts/install-local-bin.sh
```

Package the Alfred workflow:

```sh
scripts/package-alfred-workflow.sh
```

Then import:

```text
dist/Clipboard To Window.alfredworkflow
```

The workflow registers `Option-Command-V` as the hotkey. Copy an image, press the
hotkey, and the image opens in a new window. The workflow expects the executable
at `~/.local/bin/clipboard-to-window`.

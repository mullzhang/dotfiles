#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

TOOL_USE_RE = re.compile(r'<tool-use\b[^>]*>.*?</tool-use>\s*', re.DOTALL)
THINK_RE = re.compile(r'<think><details>.*?</details></think>\s*', re.DOTALL)
EMPTY_AGENT_HEADER_RE = re.compile(
    r'^_\*\*Agent[^\n]*\*\*_\n[ \t\r\n]*(?=(?:_\*\*(?:Agent|User)[^\n]*\*\*_|---\n|\Z))',
    re.MULTILINE,
)
EXCESS_BLANKS_RE = re.compile(r'\n{4,}')


def clean_markdown(text: str) -> str:
    text = TOOL_USE_RE.sub('', text)
    text = THINK_RE.sub('', text)

    previous = None
    while previous != text:
        previous = text
        text = EMPTY_AGENT_HEADER_RE.sub('', text)

    text = EXCESS_BLANKS_RE.sub('\n\n\n', text)
    return text


def destination_for_file(src: Path, output: Path) -> Path:
    if output.exists() and output.is_dir():
        return output / src.name
    if output.suffix == '.md':
        return output
    return output / src.name


def clean_file(src: Path, dest: Path) -> None:
    if src.resolve() == dest.resolve():
        raise ValueError(f'Refusing to overwrite input file: {src}')

    dest.parent.mkdir(parents=True, exist_ok=True)
    text = src.read_text(encoding='utf-8', errors='surrogateescape')
    dest.write_text(clean_markdown(text), encoding='utf-8', errors='surrogateescape')


def clean_path(input_path: Path, output_path: Path) -> Path:
    if input_path.is_file():
        dest = destination_for_file(input_path, output_path)
        clean_file(input_path, dest)
        return dest

    if input_path.is_dir():
        output_path.mkdir(parents=True, exist_ok=True)
        for src in sorted(input_path.glob('*.md')):
            clean_file(src, output_path / src.name)
        return output_path

    raise ValueError(f'Input is not a file or directory: {input_path}')


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Clean SpecStory markdown exports.')
    parser.add_argument('input', nargs='?', default='.specstory/history')
    parser.add_argument('output', nargs='?', default='.specstory/clean-history')
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    try:
        written_to = clean_path(Path(args.input), Path(args.output))
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print(f'Clean SpecStory markdown written to: {written_to}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))

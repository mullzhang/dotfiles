#!/usr/bin/env python3

from __future__ import annotations

import argparse
import glob
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

LEVEL_ORDER = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")
LEVEL_PATTERN = re.compile(r"\[(DEBUG|INFO|WARNING|WARN|ERROR|CRITICAL|FATAL)\]")


@dataclass
class LogStats:
    file_path: str
    total_lines: int = 0
    matched_lines: int = 0
    levels: dict[str, int] = field(default_factory=lambda: {level: 0 for level in LEVEL_ORDER})


def _normalize_level(level: str) -> str:
    if level in {"WARN", "WARNING"}:
        return "WARNING"
    if level in {"FATAL", "CRITICAL"}:
        return "CRITICAL"
    return level


def parse_log_file(file_path: Path) -> LogStats:
    stats = LogStats(file_path=str(file_path))
    with file_path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            stats.total_lines += 1
            match = LEVEL_PATTERN.search(line)
            if match is None:
                continue
            level = _normalize_level(match.group(1))
            stats.matched_lines += 1
            stats.levels[level] += 1

    return stats


def resolve_log_files(targets: list[str], pattern: str, recursive: bool) -> list[Path]:
    files: set[Path] = set()
    for target in targets:
        if any(token in target for token in "*?[]"):
            for matched in glob.glob(target, recursive=recursive):
                matched_path = Path(matched).expanduser()
                if matched_path.is_file():
                    files.add(matched_path.resolve())
            continue

        path = Path(target).expanduser()
        if path.is_file():
            files.add(path.resolve())
            continue

        if path.is_dir():
            iterator = path.rglob(pattern) if recursive else path.glob(pattern)
            for matched_path in iterator:
                if matched_path.is_file():
                    files.add(matched_path.resolve())
            continue

        print(f"[WARN] Target not found: {target}", file=sys.stderr)

    return sorted(files, key=lambda p: str(p))


def _ratio(count: int, total: int) -> float:
    if total <= 0:
        return 0.0
    return (count / total) * 100.0


def aggregate(stats_list: list[LogStats]) -> LogStats:
    total = LogStats(file_path="TOTAL")
    for stats in stats_list:
        total.total_lines += stats.total_lines
        total.matched_lines += stats.matched_lines
        for level in LEVEL_ORDER:
            total.levels[level] += stats.levels[level]
    return total


def _active_levels(ignore_debug: bool) -> tuple[str, ...]:
    if ignore_debug:
        return tuple(level for level in LEVEL_ORDER if level != "DEBUG")
    return LEVEL_ORDER


def _matched_lines_for_levels(stats: LogStats, levels: tuple[str, ...]) -> int:
    return sum(stats.levels[level] for level in levels)


def _format_level_cell(count: int, matched_lines: int) -> str:
    return f"{count} ({_ratio(count, matched_lines):5.1f}%)"


def print_summary(total_stats: LogStats, file_count: int, levels: tuple[str, ...], ignore_debug: bool) -> None:
    matched_lines = _matched_lines_for_levels(total_stats, levels)
    print("=== Log Level Summary ===")
    print(f"files: {file_count}")
    print(f"total_lines: {total_stats.total_lines}")
    print(f"matched_lines: {matched_lines}")
    if ignore_debug:
        print("ignore_debug: true")
    for level in levels:
        count = total_stats.levels[level]
        print(f"{level:8}: {_format_level_cell(count, matched_lines)}")


def print_per_file(stats_list: list[LogStats], levels: tuple[str, ...]) -> None:
    if not stats_list:
        return

    file_width = max(len("file"), *(len(s.file_path) for s in stats_list))
    header = (
        f"{'file'.ljust(file_width)}  {'matched'.rjust(7)}  "
        + "  ".join(level.rjust(18) for level in levels)
    )
    print("\n=== Per File ===")
    print(header)
    print("-" * len(header))

    for stats in stats_list:
        matched_lines = _matched_lines_for_levels(stats, levels)
        cells = "  ".join(_format_level_cell(stats.levels[level], matched_lines).rjust(18) for level in levels)
        print(f"{stats.file_path.ljust(file_width)}  {str(matched_lines).rjust(7)}  {cells}")


def dump_json(
    output_path: Path,
    stats_list: list[LogStats],
    total_stats: LogStats,
    levels: tuple[str, ...],
    ignore_debug: bool,
) -> None:
    payload = {
        "options": {
            "ignore_debug": ignore_debug,
            "levels": list(levels),
        },
        "summary": {
            "file_path": total_stats.file_path,
            "total_lines": total_stats.total_lines,
            "matched_lines": _matched_lines_for_levels(total_stats, levels),
            "levels": {level: total_stats.levels[level] for level in levels},
        },
        "files": [
            {
                "file_path": stats.file_path,
                "total_lines": stats.total_lines,
                "matched_lines": _matched_lines_for_levels(stats, levels),
                "levels": {level: stats.levels[level] for level in levels},
            }
            for stats in stats_list
        ],
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Calculate log-level counts and ratios from log files.")
    parser.add_argument(
        "targets",
        nargs="+",
        help="Log file paths, directories, or glob patterns (supports multiple targets).",
    )
    parser.add_argument(
        "--pattern",
        default="*.log",
        help="File pattern when target is a directory (default: *.log).",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recursively search logs in target directories or glob patterns.",
    )
    parser.add_argument(
        "--no-per-file",
        action="store_true",
        help="Show only total summary.",
    )
    parser.add_argument(
        "--json-out",
        type=Path,
        default=None,
        help="Optional path to save results in JSON.",
    )
    parser.add_argument(
        "--ignore-debug",
        action="store_true",
        help="Exclude DEBUG from counts and ratios.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    files = resolve_log_files(args.targets, pattern=args.pattern, recursive=args.recursive)
    if not files:
        print("No log files found.", file=sys.stderr)
        sys.exit(1)

    stats_list = [parse_log_file(file_path) for file_path in files]
    total_stats = aggregate(stats_list)
    levels = _active_levels(ignore_debug=args.ignore_debug)

    print_summary(total_stats, file_count=len(files), levels=levels, ignore_debug=args.ignore_debug)
    if args.no_per_file is False:
        print_per_file(stats_list, levels=levels)

    if args.json_out is not None:
        dump_json(args.json_out, stats_list, total_stats, levels=levels, ignore_debug=args.ignore_debug)
        print(f"\nJSON written to: {args.json_out}")


if __name__ == "__main__":
    main()
